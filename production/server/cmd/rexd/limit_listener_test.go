package main

import (
	"errors"
	"net"
	"testing"
	"time"
)

func TestLimitListenerBoundsSocketsAndReleasesOnClose(t *testing.T) {
	inner, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	l := newLimitListener(inner, 1)
	defer l.Close()
	client1, err := net.Dial("tcp", inner.Addr().String())
	if err != nil {
		t.Fatal(err)
	}
	defer client1.Close()
	server1, err := l.Accept()
	if err != nil {
		t.Fatal(err)
	}
	client2, err := net.Dial("tcp", inner.Addr().String())
	if err != nil {
		t.Fatal(err)
	}
	defer client2.Close()
	result := make(chan net.Conn, 1)
	go func() {
		conn, _ := l.Accept()
		result <- conn
	}()
	select {
	case conn := <-result:
		if conn != nil {
			conn.Close()
		}
		t.Fatal("accepted beyond socket limit")
	case <-time.After(30 * time.Millisecond):
	}
	if len(l.slots) != 1 {
		t.Fatal("first socket not counted")
	}
	_ = server1.Close()
	_ = server1.Close()
	select {
	case server2 := <-result:
		if server2 == nil {
			t.Fatal("second socket not accepted after release")
		}
		defer server2.Close()
	case <-time.After(time.Second):
		t.Fatal("socket slot was not released")
	}
	if len(l.slots) != 1 {
		t.Fatal("double close released an active socket")
	}
}

func TestLimitListenerCloseUnblocksCapacityWait(t *testing.T) {
	inner, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	l := newLimitListener(inner, 1)
	client, err := net.Dial("tcp", inner.Addr().String())
	if err != nil {
		t.Fatal(err)
	}
	defer client.Close()
	server, err := l.Accept()
	if err != nil {
		t.Fatal(err)
	}
	defer server.Close()
	result := make(chan error, 1)
	go func() { _, err := l.Accept(); result <- err }()
	if err := l.Close(); err != nil {
		t.Fatal(err)
	}
	select {
	case err := <-result:
		if !errors.Is(err, net.ErrClosed) {
			t.Fatalf("unexpected accept error: %v", err)
		}
	case <-time.After(time.Second):
		t.Fatal("shutdown left an accept goroutine blocked")
	}
}
