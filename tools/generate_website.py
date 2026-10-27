#!/usr/bin/env python3
"""Generate the static multilingual Sedno site from shared templates and app labels."""
import argparse
import html
import json
import os
from pathlib import Path
import re
from string import Template
import textwrap
from urllib.parse import quote

ROOT = Path(__file__).resolve().parents[1]
SITE = ROOT / 'website/SednoWebsite'
PUBLIC = SITE / 'public'
LOCALES = json.loads((SITE / 'locales.json').read_text())
ESC = html.escape
ICONS = {
    'camera': '<rect x="3" y="7" width="18" height="14" rx="3"/><path d="m8 7 2-4h4l2 4"/><circle cx="12" cy="14" r="4"/>',
    'mic': '<rect x="9" y="2" width="6" height="13" rx="3"/><path d="M5 10v2a7 7 0 0 0 14 0v-2M12 19v3M8 22h8"/>',
    'speaker': '<path d="M3 9h4l5-5v16l-5-5H3zM16 8a6 6 0 0 1 0 8M19 4a11 11 0 0 1 0 16"/>',
    'eraser': '<path d="m3 14 10-11 8 7-10 11H8zM7 10l8 7M11 21h10"/>',
    'switch': '<path d="M4 7h15l-4-4M20 17H5l4 4"/>',
    'account': '<circle cx="12" cy="12" r="9"/><circle cx="12" cy="9" r="3"/><path d="M5 18c1-5 13-5 14 0"/>',
    'back': '<path d="M20 12H4m7-7-7 7 7 7"/>',
}


def load(locale):
    fallback = json.loads((SITE / 'locales/pl.json').read_text())
    translated = json.loads((SITE / f"locales/{locale['slug']}.json").read_text())
    if translated.keys() != fallback.keys():
        raise ValueError(f"Incomplete website catalogue: {locale['slug']}")
    for key, value in fallback.items():
        actual = translated[key]
        if type(value) is not type(actual) or (isinstance(value, list) and len(value) != len(actual)):
            raise ValueError(f"Invalid catalogue field {locale['slug']}: {key}")
    app = json.loads((ROOT / 'mobile/lib/l10n/app_pl.arb').read_text())
    app.update(json.loads((ROOT / f"mobile/lib/l10n/app_{locale['arb']}.arb").read_text()))
    policy = json.loads((ROOT / f"docs/privacy-policy.{locale['policy']}.json").read_text())
    return fallback | translated, app, policy


def page_path(locale, kind='home'):
    suffix = {'home': 'index.html', 'privacy': 'privacy/index.html', 'deletion': 'delete-account/index.html', 'account': 'account/index.html'}[kind]
    return Path(locale['slug']) / suffix


def relative(source, target):
    return os.path.relpath(target, start=source.parent).replace(os.sep, '/')


def public_url(locale, kind='home'):
    if locale['slug'] == 'pl' and kind == 'account':
        return 'https://sedno.xyz/konto/'
    if locale['slug'] == 'pl' and kind == 'home':
        return 'https://sedno.xyz/'
    return 'https://sedno.xyz/' + page_path(locale, kind).parent.as_posix() + '/'


def head_links(locale, kind):
    links = [f'<link rel="canonical" href="{public_url(locale, kind)}">']
    for item in LOCALES:
        links.append(f'<link rel="alternate" hreflang="{item["lang"]}" href="{public_url(item, kind)}">')
    links.append(f'<link rel="alternate" hreflang="x-default" href="{public_url(LOCALES[0], kind)}">')
    return '\n    '.join(links)


def language_links(locale, source, kind):
    return '\n'.join(
        f'<a lang="{item["lang"]}" hreflang="{item["lang"]}" href="{relative(source, page_path(item, kind))}"'
        + (' aria-current="page"' if item['slug'] == locale['slug'] else '')
        + f'>{ESC(item["name"])}</a>' for item in LOCALES
    )


def header(locale, source, kind, c, app):
    assets = relative(source, Path('styles.css')).removesuffix('styles.css')
    home = relative(source, page_path(locale))
    how = '#jak-to-dziala' if kind == 'home' else home + '#jak-to-dziala'
    privacy = '#prywatnosc' if kind == 'home' else relative(source, page_path(locale, 'privacy'))
    return f'''<header class="header wrap">
      <a class="brand" href="{home}" aria-label="{ESC(c['homeLabel'])}"><img class="brand-mark" src="{assets}favicon.svg?v=3" width="36" height="36" alt="" aria-hidden="true">sedno<span class="brand-dot" aria-hidden="true">.</span></a>
      <nav class="main-nav" aria-label="{ESC(c['navLabel'])}"><a href="{how}">{ESC(app['howItWorks'])}</a><a href="{privacy}">{ESC(c['privacyLabel'])}</a><a href="{relative(source, page_path(locale, 'account'))}">{ESC(c['accountGuideTitle'])}</a></nav>
      <details class="language-menu">
        <summary><span>{ESC(app['language'])}</span> <span lang="{locale['lang']}">{ESC(locale['name'])}</span></summary>
        <nav class="language-options" aria-label="{ESC(app['language'])}">{language_links(locale, source, kind)}</nav>
      </details>
    </header>'''


def footer(locale, source, c, app):
    home = relative(source, page_path(locale))
    privacy = relative(source, page_path(locale, 'privacy'))
    deletion = relative(source, page_path(locale, 'deletion'))
    return f'''<footer class="footer wrap">
      <a class="brand footer-brand" href="{home}" aria-label="{ESC(c['homeLabel'])}">sedno.</a>
      <nav class="footer-links" aria-label="{ESC(c['documentsLabel'])}"><a href="{privacy}">{ESC(c['privacyLabel'])}</a><a href="{deletion}">{ESC(c['deletionLabel'])}</a></nav>
      <p>{ESC(app['contact'])}: contact@sedno.xyz <a href="mailto:contact@sedno.xyz">{ESC(c['write'])}</a></p>
      <a href="#tresc">{ESC(c['backTop'])} <span aria-hidden="true">↑</span></a>
    </footer>'''


def icon(name):
    return '<svg viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">' + ICONS[name] + '</svg>'


def control(content, marked=False, cls=''):
    return f'<span class="control-picture {cls}' + (' marked' if marked else '') + '">' + content + '</span>'


def phone(text, app, mode='simplify', result=False, target=None):
    heading = app['correctedText' if mode == 'correct' else 'simplifiedText'] if result else 'Sedno – ' + app[mode + 'Heading'] + ':'
    side = 'speaker' if mode == 'correct' else 'mic'
    warning = f'<p class="picture-warning">{ESC(app["aiWarning"])}</p>' if result else ''
    right = control(icon('camera'), target == 'camera', 'side-picture') if mode == 'simplify' else '<span class="side-placeholder"></span>'
    return f'''<div class="phone-picture">
  <div class="phone-heading"><span>{ESC(heading)}</span>{icon('account')}</div>
  <div class="editor-picture"><p>{ESC(text)}</p>{warning}</div>
  <div class="mode-picture">{icon('switch')}{icon('eraser')}</div>
  <div class="actions-picture">{control(icon(side), target == side, 'side-picture')}{control(ESC(app[mode]), target == 'submit', 'primary-picture')}{right}</div>
</div>'''


def photo_screen(locale, source, c, app, crop=False):
    title = app['selectText' if crop else 'takeTextPhoto']
    label = app['simplify' if crop else 'takePhoto']
    picture = relative(source, Path(f"img/kartka-z-tekstem.{locale['slug']}{'.crop' if crop else ''}.svg"))
    hint = f'<p class="crop-hint">{ESC(app["cropInstructions"].strip())}</p>' if crop else ''
    return f'''<div class="phone-picture photo-phone">
  <div class="phone-heading">{icon('back')}<span>{ESC(title)}</span></div>{hint}
  <div class="photo-preview{' crop-preview' if crop else ''}">
    <img src="{picture}" width="640" height="840" alt="{ESC(c['paperTitle'] + ': ' + c['sampleOriginal'])}">
  </div>
  <div class="photo-action">{control(('' if crop else icon('camera')) + ESC(label), True, 'capture-picture')}</div>
</div>'''


def sound(c, listen=False):
    heights = [16, 26, 44, 66, 38, 84, 106, 58, 126, 94, 52, 112, 72, 40, 90, 58, 30, 46, 22]
    bars = ''.join(f'<rect x="{30+i*12}" y="{100-h/2:g}" width="5" height="{h}" rx="2.5"/>' for i, h in enumerate(heights))
    title = c['soundRead' if listen else 'soundSpeak']
    caption = c['soundListen' if listen else 'soundConvert']
    return f'''<div class="sound-picture" role="img" aria-label="{ESC(title + '. ' + caption)}">
  <span class="sound-symbol" aria-hidden="true">{icon('speaker' if listen else 'mic')}</span>
  <svg class="sound-wave" viewBox="0 0 280 200" width="280" height="200" aria-hidden="true"><path d="M12 100h256" fill="none" stroke="#9bb9ed" stroke-width="2"/><g fill="#0057b7">{bars}</g></svg>
  <p>{ESC(title)}</p><span class="sound-caption">{ESC(caption)}</span>
</div>'''


def instructions(locale, source, c, app):
    drawings = [
        phone(c['sampleOriginal'], app, target='submit'), phone(c['sampleSimple'], app, result=True),
        phone(app['inputHint'], app, target='camera'), photo_screen(locale, source, c, app),
        photo_screen(locale, source, c, app, crop=True), phone(c['sampleSimple'], app, result=True),
        phone(app['inputHint'], app, target='mic'), sound(c), phone(c['sampleSimple'], app, result=True),
        phone(c['sampleWrong'], app, mode='correct', target='submit'), phone(c['sampleCorrect'], app, mode='correct', result=True),
        phone(c['sampleCorrect'], app, mode='correct', result=True, target='speaker'), sound(c, listen=True),
    ]
    groups = [('tekst-pisany', 0, 2, None), ('tekst-ze-zdjecia', 2, 6, 'photoNote'), ('tekst-z-mowy', 6, 9, 'speechNote'), ('poprawianie', 9, 11, None), ('odczyt', 11, 13, 'playbackNote')]
    articles = []
    for group_index, (id_, start, end, note_key) in enumerate(groups):
        frames = []
        for index in range(start, end):
            title = ESC(c['frameTitles'][index].format_map(app))
            desc = ESC(c['frameDescriptions'][index].format_map(app))
            frames.append(f'''<li class="walkthrough-step"><h4><span class="instruction-number">{index-start+1}</span> {title}</h4>
  <p>{desc}</p><div class="diagram">{drawings[index]}</div></li>''')
        note = f'<p class="walkthrough-note">{ESC(c[note_key])}</p>' if note_key else ''
        articles.append(f'''<article class="walkthrough" aria-labelledby="{id_}">
  <h3 id="{id_}">{ESC(c['exampleTitles'][group_index])}</h3><p class="walkthrough-intro">{ESC(c['exampleIntros'][group_index].format_map(app))}</p>
  <ol class="walkthrough-frames">{chr(10).join(frames)}</ol>{note}
</article>''')
    return '\n'.join(articles)


def home_page(locale, source):
    c, app, _ = load(locale)
    values = {k: ESC(v) for k, v in c.items() if isinstance(v, str)}
    values.update({k: ESC(app[k]) for k in ('originalText', 'simplifiedText', 'localMediaNotice', 'language')})
    values.update({
        'lang': locale['lang'], 'assets': relative(source, Path('styles.css')).removesuffix('styles.css'),
        'heroTitle0': ESC(c['heroTitle'][0]), 'heroTitle1': ESC(c['heroTitle'][1]),
        'header': header(locale, source, 'home', c, app), 'footer': footer(locale, source, c, app),
        'head_links': head_links(locale, 'home'), 'language_links': language_links(locale, source, 'home'),
        'privacy_url': relative(source, page_path(locale, 'privacy')),
        'overview_steps': ''.join(f'<li><span class="step-number" aria-hidden="true">0{i+1}</span><h3>{ESC(title)}</h3><p>{ESC(desc)}</p></li>' for i, (title, desc) in enumerate(zip(c['stepTitles'], c['stepDescriptions']))),
        'instructions': instructions(locale, source, c, app),
        'help_items': ''.join(f'<li>{ESC(item)}</li>' for item in (app['restoreInstructions'], c['copyHelp'], c['clearHelp'], c['submissionHelp'])),
        'privacy_items': ''.join(f'<div><dt>{ESC(title)}</dt><dd>{ESC(desc)}</dd></div>' for title, desc in zip(c['privacyTitles'], c['privacyDescriptions'])),
    })
    return Template((SITE / 'templates/home.html').read_text()).substitute(values)


def account_page(locale, source):
    c, app, _ = load(locale)
    assets = relative(source, Path('styles.css')).removesuffix('styles.css')
    steps = []
    screens = ['home', 'menu', 'sign-in', 'register', None, 'verify', 'done']
    for i, screen in enumerate(screens):
        title = c['accountGuideSteps'][i].format_map(app)
        description = c['accountGuideDescriptions'][i].format_map(app)
        if screen:
            url = relative(source, Path(f"img/account/{locale['slug']}-{screen}.png"))
            drawing = f'<a class="guide-image-link" href="{url}"><img src="{url}" width="824" height="1830" alt="{ESC(title + '. ' + description)}" loading="lazy"></a>'
        else:
            # Deliberately a drawing: no real mailbox, link, or personal data.
            drawing = f'''<div class="guide-mail" role="img" aria-label="{ESC(c['accountGuideMailTitle'] + '. ' + c['accountGuideMailBody'] + ' ' + c['accountGuideMailLink'])}">
              <p class="guide-mail-label">{ESC(c['accountGuideMailTitle'])}</p>
              <span class="guide-envelope" aria-hidden="true">✉</span><p><strong>Sedno</strong></p>
              <p>{ESC(c['accountGuideMailBody'])}</p>
              <span class="guide-mail-confirm">{ESC(c['accountGuideMailLink'])}</span></div>'''
        tap = f'<p class="guide-tap">{ESC(c["accountGuideTap"])}</p>' if i < 6 and i != 3 else ''
        directions = ('<ol class="guide-fields">' + ''.join(f'<li>{ESC(part.rstrip("."))}.</li>' for part in description.split('. ')) + '</ol>') if i == 3 else f'<p>{ESC(description)}</p>'
        steps.append(f'''<li class="guide-step" id="krok-{i+1}">
          <div class="guide-copy"><h2><span class="guide-number">{i+1}</span> {ESC(title)}</h2>
          {directions}{tap}</div><figure>{drawing}</figure></li>''')
    return f'''<!doctype html>
<!-- Generated by tools/generate_website.py. -->
<html lang="{locale['lang']}"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Sedno — {ESC(c['accountGuideTitle'])}</title><meta name="description" content="{ESC(c['accountGuideIntro'])}">
<link rel="icon" href="{assets}favicon.svg?v=3" type="image/svg+xml"><link rel="stylesheet" href="{assets}styles.css">
{head_links(locale, 'account')}</head><body><a class="skip-link" href="#tresc">{ESC(c['skip'])}</a>
{header(locale, source, 'account', c, app)}
<main class="account-guide wrap" id="tresc" tabindex="-1">
<div class="guide-intro"><h1>{ESC(c['accountGuideTitle'])}</h1><p>{ESC(c['accountGuideIntro'])}</p>
<p class="diagram-note">{ESC(c['accountGuideNote'])}</p></div>
<ol class="guide-steps">{''.join(steps)}</ol>
<aside class="guide-help"><h2>{ESC(c['helpTitle'])}</h2><p>{ESC(c['accountGuideHelp'].format_map(app))}</p></aside>
</main>{footer(locale, source, c, app)}</body></html>
'''


def paper_svg(locale, crop=False):
    c, _, _ = load(locale)
    title_lines = textwrap.wrap(c['paperTitle'], width=26)
    lines = textwrap.wrap(c['sampleOriginal'], width=27)
    def text_block(lines, y, size, bold=False):
        spans = ''.join(f'<tspan x="133" dy="{0 if i == 0 else 37}">{ESC(line)}</tspan>' for i, line in enumerate(lines))
        return f'<text x="133" y="{y}" font-size="{size}"' + (' font-weight="bold"' if bold else '') + '>' + spans + '</text>'
    text = text_block(title_lines, 218, 25, True) + text_block(lines, 284, 23)
    drawing = Template((SITE / 'templates/paper.svg').read_text()).substitute(lang=locale['lang'], paperTitle=ESC(c['paperTitle']), paper_text=text)
    if crop:
        # Keep the selection attached to the photograph at every display size.
        overlay = '<defs><mask id="selection-window"><rect width="640" height="840" fill="white"/><rect x="118" y="258" width="415" height="202" fill="black"/></mask></defs>'
        overlay += '<rect width="640" height="840" fill="#000" opacity=".4" mask="url(#selection-window)"/>'
        overlay += '<rect x="118" y="258" width="415" height="202" fill="none" stroke="black" stroke-width="8"/><rect x="118" y="258" width="415" height="202" fill="none" stroke="white" stroke-width="4"/>'
        overlay += ''.join(f'<circle cx="{x}" cy="{y}" r="15" fill="#0057b7" stroke="white" stroke-width="4"/>' for x, y in ((118, 258), (533, 258), (118, 460), (533, 460)))
        drawing = drawing.replace('</svg>', overlay + '</svg>')
    return drawing


def linked_text(value):
    """Link existing policy addresses without losing adjacent sentence punctuation."""
    parts, start = [], 0
    for match in re.finditer(r'https?://[^\s<>]+|contact@sedno\.xyz', value):
        url = match.group().rstrip('.,;')
        parts.append(ESC(value[start:match.start()]))
        href = 'mailto:' + url if '@' in url and not url.startswith('http') else url
        parts.append(f'<a href="{ESC(href)}">{ESC(url)}</a>')
        start = match.start() + len(url)
    parts.append(ESC(value[start:]))
    return ''.join(parts)


def document_page(locale, source, kind):
    c, app, policy = load(locale)
    title = policy['title'] if kind == 'privacy' else 'Sedno — ' + c['deletionLabel']
    indices = range(len(policy['sections'])) if kind == 'privacy' else (0, 2, 8, 9, 10)
    sections = '\n'.join('<section><h2>' + ESC(policy['sections'][i]['title']) + '</h2>' + ''.join('<p>' + linked_text(p) + '</p>' for p in policy['sections'][i]['paragraphs']) + '</section>' for i in indices)
    request = f'<p><a class="button" href="mailto:{policy["email"]}?subject={quote(c["deletionSubject"])}">{ESC(c["deletionRequest"])}</a></p>' if kind == 'deletion' else ''
    sources = ''.join(f'<li><a href="{ESC(item["url"])}">{ESC(item["title"])}</a></li>' for item in policy['sources'])
    assets = relative(source, Path('styles.css')).removesuffix('styles.css')
    return f'''<!doctype html>
<!-- Generated by tools/generate_website.py from the versioned app policy. -->
<html lang="{locale['lang']}"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>{ESC(title)}</title><link rel="icon" href="{assets}favicon.svg?v=3" type="image/svg+xml"><link rel="stylesheet" href="{assets}styles.css">
{head_links(locale, kind)}</head><body><a class="skip-link" href="#tresc">{ESC(c['skip'])}</a>
{header(locale, source, kind, c, app)}
<main class="document wrap" id="tresc" tabindex="-1"><h1>{ESC(title)}</h1><p>{ESC(c['versionPrefix'])}: <time datetime="{policy['version']}">{ESC(policy['versionLabel'])}</time></p>
{request}{sections}<h2>{ESC(c['sourcesTitle'])}</h2><ul>{sources}</ul></main>{footer(locale, source, c, app)}</body></html>
'''


def legacy_pages():
    """Polish legacy URLs remain available, with the same language switcher."""
    return {
        'website/SednoWebsite/public/prywatnosc/index.html': document_page(LOCALES[0], Path('prywatnosc/index.html'), 'privacy'),
        'website/SednoWebsite/public/usun-konto/index.html': document_page(LOCALES[0], Path('usun-konto/index.html'), 'deletion'),
    }


def generate():
    documents = {}
    for locale in LOCALES:
        for kind in ('home', 'privacy', 'deletion', 'account'):
            path = page_path(locale, kind)
            documents['website/SednoWebsite/public/' + path.as_posix()] = home_page(locale, path) if kind == 'home' else account_page(locale, path) if kind == 'account' else document_page(locale, path, kind)
        for crop in (False, True):
            suffix = '.crop' if crop else ''
            documents[f"website/SednoWebsite/public/img/kartka-z-tekstem.{locale['slug']}{suffix}.svg"] = paper_svg(locale, crop)
    documents['website/SednoWebsite/public/index.html'] = home_page(LOCALES[0], Path('index.html'))
    documents.update(legacy_pages())
    documents['website/SednoWebsite/public/konto/index.html'] = account_page(LOCALES[0], Path('konto/index.html'))
    urls = [public_url(locale, kind) for locale in LOCALES for kind in ('home', 'privacy', 'deletion', 'account')]
    documents['website/SednoWebsite/public/sitemap.xml'] = '<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n' + ''.join(f'  <url><loc>{url}</loc></url>\n' for url in urls) + '</urlset>\n'
    return documents


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    stale = []
    documents = generate()
    for name, content in documents.items():
        path = ROOT / name
        if args.check:
            if not path.exists() or path.read_text() != content:
                stale.append(name)
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content)
    if stale:
        raise SystemExit('Nieaktualne pliki strony: ' + ', '.join(stale))
    print(f"{'Sprawdzono' if args.check else 'Wygenerowano'} {len(documents)} plików dla {len(LOCALES)} wariantów językowych.")
