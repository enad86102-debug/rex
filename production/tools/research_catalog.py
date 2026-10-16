#!/usr/bin/env python3
"""Collect public GitHub metadata only; never download or execute repository code."""
import argparse
import datetime
import json
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

QUERIES = [
    ('multiplayer', 'topic:multiplayer'),
    ('card-games', 'card game'),
    ('game-servers', 'game server language:Go'),
    ('flutter-games', 'flutter game'),
    ('qa', 'topic:testing'),
    ('security', 'topic:security'),
    ('load-testing', 'load testing'),
    ('fuzzing', 'topic:fuzzing'),
    ('mobile-security', 'android security'),
    ('design', 'topic:design-system'),
    ('3d-assets', 'gltf'),
    ('skills', 'agent skills'),
    ('design-skills', 'design skills'),
    ('security-skills', 'security skills'),
    ('observability', 'topic:observability'),
    ('reliability', 'chaos engineering'),
]


def collect(output):
    found = {}
    searches = []
    for category, query in QUERIES:
        query += ' archived:false fork:false'
        url = 'https://api.github.com/search/repositories?' + urllib.parse.urlencode(
            {'q': query, 'sort': 'stars', 'order': 'desc', 'per_page': 100})
        for attempt in range(8):
            try:
                req = urllib.request.Request(url, headers={
                    'Accept': 'application/vnd.github+json', 'User-Agent': 'REX-public-research'})
                with urllib.request.urlopen(req, timeout=40) as response:
                    data = json.load(response)
                break
            except urllib.error.HTTPError as error:
                if error.code not in (403, 429, 502, 503) or attempt == 7:
                    raise
                time.sleep(min(10 * (attempt + 1), 60))
        searches.append({'category': category, 'query': query, 'url': url,
                         'total_count': data['total_count'], 'returned': len(data['items']),
                         'incomplete_results': data.get('incomplete_results', False)})
        for item in data['items']:
            name = item['full_name']
            if name not in found:
                found[name] = {key: item.get(key) for key in (
                    'full_name', 'html_url', 'description', 'language', 'stargazers_count',
                    'pushed_at', 'archived', 'topics', 'default_branch')}
                found[name]['license'] = (item.get('license') or {}).get('spdx_id')
                found[name]['categories'] = []
                found[name]['review_level'] = 'metadata_only_not_code_reviewed'
            found[name]['categories'].append(category)
        report = {'collected_at': datetime.datetime.now(datetime.timezone.utc).isoformat(),
                  'method': 'GitHub public repository search, first 100 by stars per query; deduplicated',
                  'not_an_endorsement': True, 'unique_count': len(found),
                  'searches': searches, 'repositories': list(found.values())}
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
        print(f'{category}: {len(found)} unique repositories', flush=True)
        time.sleep(2)
    if len(found) < 1000:
        raise RuntimeError(f'Only {len(found)} unique repositories; do not claim 1000')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--output', type=Path, required=True)
    collect(parser.parse_args().output)
