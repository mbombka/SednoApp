"""Regression checks for locale coverage, app labels and the static navigation graph."""
from html.parser import HTMLParser
import json
from pathlib import Path
import re
import sys
import unittest
from urllib.parse import unquote, urlsplit
import xml.etree.ElementTree as ET

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import generate_website as site


class Page(HTMLParser):
    def __init__(self, content):
        super().__init__(convert_charrefs=True)
        self.tags = []
        self.ids = []
        self.text = []
        self.feed(content)

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        self.tags.append((tag, attrs))
        if 'id' in attrs:
            self.ids.append(attrs['id'])

    def handle_data(self, text):
        self.text.append(text)


class WebsiteTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.documents = site.generate()
        cls.pages = {site.ROOT / path: Page(content) for path, content in cls.documents.items() if path.endswith('.html')}

    def test_catalogues_cover_app_languages_and_regions(self):
        source = (site.ROOT / 'mobile/lib/features/shared/domain/app_language.dart').read_text()
        variants = re.findall(r"\w+\('([^']+)', '([^']+)', '([^']+)'\)", source)
        self.assertEqual(len(variants), 13)
        expected = {(code.replace('-', '_'), name) for code, tag, name in variants}
        actual = {(locale['arb'], locale['name']) for locale in site.LOCALES}
        self.assertEqual(actual, expected)
        self.assertEqual(len({l['lang'] for l in site.LOCALES}), 13)
        self.assertEqual(next(l for l in site.LOCALES if l['slug'] == 'en')['lang'], 'en-GB')
        self.assertEqual(next(l for l in site.LOCALES if l['slug'] == 'pt')['lang'], 'pt-PT')
        for locale in site.LOCALES:
            catalog, app, policy = site.load(locale)
            for key, value in catalog.items():
                for text in value if isinstance(value, list) else [value]:
                    self.assertTrue(text.strip(), (locale['slug'], key))
                    text.format_map(app)  # No missing app labels or unresolved placeholders.
            self.assertEqual(len(catalog['frameTitles']), 13)
            self.assertEqual(len(catalog['frameDescriptions']), 13)

    def test_relative_links_and_anchors_resolve_for_every_page(self):
        for path, page in self.pages.items():
            self.assertEqual(len(page.ids), len(set(page.ids)), path)
            for tag, attrs in page.tags:
                self.assertNotEqual(tag, 'script', path)
                for attribute in ('href', 'src'):
                    if attribute not in attrs:
                        continue
                    url = urlsplit(attrs[attribute])
                    if url.scheme or url.netloc:
                        continue
                    target = (path.parent / unquote(url.path)).resolve() if url.path else path
                    self.assertTrue(target.is_relative_to(site.PUBLIC), (path, target))
                    self.assertTrue(target.is_file(), (path, target))
                    if url.fragment:
                        target_page = self.pages.get(target) or Page(target.read_text())
                        self.assertIn(url.fragment, target_page.ids, (path, target, url.fragment))

    def test_language_switches_stay_on_the_same_document(self):
        for locale in site.LOCALES:
            for kind in ('home', 'privacy', 'deletion', 'account'):
                source = site.page_path(locale, kind)
                page = self.pages[site.PUBLIC / source]
                languages = [attrs for tag, attrs in page.tags if tag == 'html']
                self.assertEqual(languages[0]['lang'], locale['lang'])
                alternates = [attrs for tag, attrs in page.tags if tag == 'link' and attrs.get('rel') == 'alternate']
                self.assertEqual({a['hreflang'] for a in alternates}, {l['lang'] for l in site.LOCALES} | {'x-default'})
                links = [attrs for tag, attrs in page.tags if tag == 'a' and 'hreflang' in attrs]
                for other in site.LOCALES:
                    expected = site.relative(source, site.page_path(other, kind))
                    self.assertTrue(any(a['href'] == expected and a['hreflang'] == other['lang'] for a in links))
                current = [a for a in links if a.get('aria-current') == 'page']
                self.assertTrue(current)
                self.assertTrue(all(a['hreflang'] == locale['lang'] for a in current))

    def test_diagrams_use_app_labels_and_localized_paper(self):
        for locale in site.LOCALES:
            c, app, _ = site.load(locale)
            source = site.page_path(locale)
            content = self.documents['website/SednoWebsite/public/' + source.as_posix()]
            page = self.pages[site.PUBLIC / source]
            visible = ''.join(page.text)
            for key in ('simplify', 'correct', 'takePhoto', 'takeTextPhoto', 'selectText', 'simplifiedText', 'correctedText', 'aiWarning'):
                self.assertIn(app[key], visible, (locale['slug'], key))
            self.assertEqual(content.count('class="phone-picture'), 11)
            self.assertEqual(content.count('class="sound-picture"'), 2)
            for warning in re.findall(r'<p class="picture-warning">(.*?)</p>', content):
                self.assertEqual(warning, site.ESC(app['aiWarning']))
            for suffix in ('', '.crop'):
                svg_path = f"website/SednoWebsite/public/img/kartka-z-tekstem.{locale['slug']}{suffix}.svg"
                paper = ET.fromstring(self.documents[svg_path])
                self.assertEqual(paper.attrib['{http://www.w3.org/XML/1998/namespace}lang'], locale['lang'])
                text = ' '.join(t.text or '' for t in paper.iter('{http://www.w3.org/2000/svg}tspan'))
                self.assertIn(c['sampleOriginal'], text)
                self.assertIn('kartka-z-tekstem.' + locale['slug'] + suffix + '.svg', content)
                if suffix:
                    self.assertIsNotNone(paper.find('.//{http://www.w3.org/2000/svg}mask'))


    def test_account_guide_covers_registration_and_confirmation(self):
        for locale in site.LOCALES:
            c, app, _ = site.load(locale)
            source = site.page_path(locale, 'account')
            content = self.documents['website/SednoWebsite/public/' + source.as_posix()]
            page = self.pages[site.PUBLIC / source]
            visible = ''.join(page.text)
            self.assertEqual(len(c['accountGuideSteps']), 7)
            self.assertEqual(len(c['accountGuideDescriptions']), 7)
            self.assertEqual(content.count('class="guide-step"'), 7)
            for key in ('createAccountLink', 'createAccount', 'checkVerification', 'resendEmail'):
                self.assertIn(app[key], visible, (locale['slug'], key))
            images = [attrs for tag, attrs in page.tags if tag == 'img' and '/account/' in attrs.get('src', '')]
            self.assertEqual(len(images), 6)
            for attrs in images:
                self.assertTrue(attrs['alt'].strip())
                path = (site.PUBLIC / source.parent / attrs['src']).resolve()
                data = path.read_bytes()
                self.assertEqual(data[:8], b'\x89PNG\r\n\x1a\n')
                self.assertEqual(int.from_bytes(data[16:20], 'big'), 824)
                self.assertEqual(int.from_bytes(data[20:24], 'big'), 1830)
            # The simulated email cannot submit data or open a fake verification URL.
            self.assertFalse(any(tag in ('form', 'input', 'button') for tag, _ in page.tags))
            self.assertIn(site.public_url(locale, 'account'), self.documents['website/SednoWebsite/public/sitemap.xml'])
        alias = self.pages[site.PUBLIC / 'konto/index.html']
        self.assertIn(('link', {'rel': 'canonical', 'href': 'https://sedno.xyz/konto/'}), alias.tags)
        self.assertEqual(site.public_url(site.LOCALES[0], 'account'), 'https://sedno.xyz/konto/')

    def test_document_contains_full_versioned_policy(self):
        for locale in site.LOCALES:
            _, _, policy = site.load(locale)
            path = site.PUBLIC / site.page_path(locale, 'privacy')
            visible = ''.join(self.pages[path].text)
            for section in policy['sections']:
                self.assertIn(section['title'], visible)
                for paragraph in section['paragraphs']:
                    self.assertIn(paragraph, visible)
            deletion = self.pages[site.PUBLIC / site.page_path(locale, 'deletion')]
            self.assertIn(policy['deletionNotice'], ''.join(deletion.text))
            mail = [a['href'] for tag, a in deletion.tags if tag == 'a' and a.get('href', '').startswith('mailto:contact@sedno.xyz?subject=')]
            self.assertEqual(len(mail), 1)

    def test_policy_linkification_keeps_punctuation_and_escapes_markup(self):
        value = 'Read https://sedno.xyz/privacy/. Write contact@sedno.xyz; <private> & data.'
        page = Page(site.linked_text(value))
        self.assertEqual(''.join(page.text), value)
        self.assertEqual([a['href'] for tag, a in page.tags if tag == 'a'], ['https://sedno.xyz/privacy/', 'mailto:contact@sedno.xyz'])
        self.assertFalse(any(tag == 'private' for tag, _ in page.tags))


if __name__ == '__main__':
    unittest.main()
