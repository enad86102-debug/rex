package main

import (
	"net"
	"sync"
)

// limitListener bounds accepted sockets, including idle keep-alive clients and
// clients that never finish a TLS handshake or HTTP header. It complements the
// API's in-flight work limit; neither is a distributed rate limiter.
type limitListener struct {
	net.Listener
	slots   chan struct{}
	closing chan struct{}
	once    sync.Once
}

func newLimitListener(inner net.Listener, maxConnections int) *limitListener {
	return &limitListener{Listener: inner, slots: make(chan struct{}, maxConnections), closing: make(chan struct{})}
}

func (l *limitListener) Accept() (net.Conn, error) {
	select {
	case l.slots <- struct{}{}:
	case <-l.closing:
		return nil, net.ErrClosed
	}
	conn, err := l.Listener.Accept()
	if err != nil {
		<-l.slots
		return nil, err
	}
	return &limitedConn{Conn: conn, release: func() { <-l.slots }}, nil
}

func (l *limitListener) Close() error {
	var err error
	l.once.Do(func() {
		close(l.closing)
		err = l.Listener.Close()
	})
	return err
}

type limitedConn struct {
	net.Conn
	release func()
	once    sync.Once
}

func (c *limitedConn) Close() error {
	err := c.Conn.Close()
	c.once.Do(c.release)
	return err
}
