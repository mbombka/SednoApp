# Personvern og data

Versjon: 2026-10-23

## Behandlingsansvarlig og brukere

Behandlingsansvarlig: Mariusz Bąbka, privatperson, ul. Słowiańska 91, Modlniczka, Polen; contact@sedno.xyz. Ingen personvernombud er utnevnt. Polen er første marked. Sedno er for personer fra 13 år; 13–17-åringer bør ha tillatelse fra forelder eller verge. Vi kontrollerer ikke alder og samler ikke inn fødselsdato. Polske opplysninger: https://sedno.xyz/prywatnosc/, https://sedno.xyz/#prywatnosc; kontosletting: https://sedno.xyz/usun-konto. Serveren har vært i drift siden 19. oktober 2026.

## Tekst og kunstig intelligens

Teksten sendes gjennom Sedno-serveren til OpenAI for forenkling eller retting. Ikke legg inn opplysninger du ikke vil dele. Bilder og lyd blir på enheten. Bare tekst sendes til KI. Opplesing bruker en nedlastet lokal stemme. KI kan gjøre feil. Kontroller resultatet.

Vi bruker OpenAI Responses API. Sedno behandler tekst og resultat bare i minnet, ikke i database eller logger; sender ikke bilder eller hele historikken. store=false betyr ikke at leverandøren lagrer ingenting. API-data brukes normalt ikke til trening; sikkerhetslogger kan inneholde innhold i opptil 30 dager, med leverandørens unntak og midlertidige hurtigbuffere. Vi lover ikke behandling bare i EU. Ikke send helseopplysninger, opplysninger om funksjonsnedsettelse eller andre særlig beskyttede data; fjern unødvendige personopplysninger om deg selv og andre. Bruk er ikke et generelt samtykke.

## Slette konto

Vi sletter Sedno-kontoen, serverdata og lokal historikk på denne enheten. Handlingen kan ikke angres. Kontosletting avslutter ikke abonnementet. Stopp betalingene i Google Play → Betalinger og abonnementer → Abonnementer → Sedno → Si opp abonnement.

I appen: Konto → Slett konto → Slett konto og data. Vi fjerner Firebase-identitet, økter, tilknyttede installasjoner, forespørselsmetadata og kjøpsoppføringer, ikke Google-kontoen. Uten app: skriv til contact@sedno.xyz med emnet «Slett Sedno-konto» og e-posten du logger inn med. Ikke send passord, koder, tokener, dokumenter, bilder eller tekster. E-post alene sletter ikke kontoen: vi kontrollerer kontotilgang med bare nødvendige opplysninger. Historikk på andre enheter sletter du i Historikk eller Android-appdata; vi har ikke fjerntilgang. Googles egne data følger deres regler.

## Bilder, tale og lokale data

Bilder, beskjæring og OCR behandles på enheten. Gjenkjent tekst sendes til forenkling og kan redigeres etter feil eller avbrudd. Appen prøver å slette arbeidskopier etter lesing, feil eller avbrudd; brå avslutning kan avbryte rydding. Kopier fra andre kameraapper styrer du selv.

Diktering er lokal på støttet Android 13+ med nedlastet modell for valgt språk. Lyd ligger bare i minnet, uten fil eller sending til Sedno eller OpenAI. Avsluttes etter 1,5 sekunders stillhet etter tale eller senest etter 60 sekunder; Stopp avbryter. Bare teksten går til KI. Opplesing i rettemodus krever lokal stemme uten nettverk. Nedlasting av modeller og stemmer kan kreve internett og følger leverandørens vilkår. Kamera og mikrofon er valgfrie.

Kryptert lokal historikk inneholder original, resultat, modus, språk og dato; unntatt fra Android-sikkerhetskopier. Utløper etter 7 dager; utløpte oppføringer vises ikke og slettes ved lesing, oppstart og gjenopptakelse, eller neste hendelse når appen er lukket. Du kan slette tidligere; utlogging tømmer historikken. Beskyttet økt, tilfeldig installasjons-ID og manuelt språkvalg lagres også lokalt. Kontosletting fjerner ikke lokal ID; tøm Android-appdata.

## Konto, grenser og betaling

Konto er valgfri. Firebase Authentication håndterer Google eller e-post og passord; Sedno lagrer UID, innloggingsmetode og dato, ikke passord. Google kan behandle profil, e-post, IP og forbindelsesdata. Grenser bruker pseudonyme installasjons-, økt- og forespørsels-ID-er, datoer, statuser og HMAC-avtrykk, ikke tekstkopier. De er ikke anonyme; innlogging fornyer ikke gratisgrensen. IP begrenser forespørsler, er ikke et felt i Sedno-databasen, men kan behandles av infrastrukturen. Play Integrity kontrollerer app og enhet uten tekst eller bilder. Google Play håndterer betaling; Sedno får ikke kort- eller bankkonto, lagrer kryptert kjøpstoken, hash, kontotilknytning, status, gyldighet, kontroll og varsel-ID-er mot duplikater.

## Leverandører og tekniske data

OpenAI: tekst og sikkerhet; standardavtalen for Polen viser til OpenAI Ireland Ltd. Google Ireland Limited og Google LLC: Firebase Authentication, Google Sign-In, ML Kit, Play Integrity og Google Play etter produkt. OVHcloud: e-post sedno.xyz. ML Kit kan sende installasjons-ID, modell, versjon, feil og tidsbruk, ikke bilde eller gjenkjent tekst i denne telemetrien. Lokal OCR utelukker ikke kommunikasjon. Ingen reklame, Firebase Analytics eller Crashlytics. Cloud Run, Firestore Standard europe-central2 (Warszawa), Firebase Hosting; polsk standard Cloud-avtale Google Cloud Poland Sp. z o.o. En aktiv tjeneste bekrefter ikke ferdige avtaler eller kontroller før publisering.

## Formål og behandlingsgrunnlag

GDPR artikkel 6 nr. 1 bokstav b: tekst, konto og abonnement for avtale eller forespurte tiltak. Bokstav f: sikkerhet, misbruksvern, grenser og vanlig brukerstøtte, nødvendige metadata uten reklame; innsigelser vurderes individuelt. Bokstav c, artikkel 12–22: personvernrettigheter; artikkel 5 nr. 2 og 24: minimal dokumentasjon. Installasjon, KI-varsel og kameratillatelse er ikke generelt samtykke. Eventuelt samtykke til SDK-diagnostikk må vurderes og innføres før produksjon, policyen erstatter det ikke. Nødvendige data kreves for aktuell funksjon; konto og kjøp er valgfrie. Ingen reklameprofilering eller rettslige avgjørelser basert på KI-resultat. Meld feil blokkering til ansvarlig.

## Overføring utenfor EØS

Google og OpenAI kan behandle utenfor EØS, også USA; Firebase Authentication bruker amerikansk infrastruktur. Database i Warszawa garanterer ikke at alle data blir i EØS. Produksjon krever avtaler og egnede overføringsgarantier. Leverandørene beskriver standardklausuler og adekvansbeslutninger for omfattede mottakere; merkenavnet er ikke en garanti. Be ansvarlig om vilkår og kopier av brukte garantier; kilder følger nedenfor.

## Lagring i Sedno

Tekst og resultat bare i minnet; lokal historikk 7 dager. En timebasert oppgave uavhengig av trafikk sletter metadata og HMAC eldre enn 8 dager; daglige tellere og reservasjoner opptil 8 dager. Kontoøkter 7 dager, gjesteøkter 90; ugyldige avvises før fysisk sletting. Ikke-tilknyttede gjesteidentiteter eldre enn 90 dager slettes når de ikke har økter eller forespørsler, muligens senere. Kontoer, tilknyttede installasjoner og kjøp beholdes til kontosletting; inaktive kontoer og utløpte kjøp slettes ikke automatisk. Play-varsel-ID-er utløper ikke automatisk og har ikke kjøpstoken eller kontotilknytning. Vi lover ikke frister som ikke er innført.

## Driftsregler for lagring

Vedtatte produksjonsregler: tekniske logger og sikkerhetskopier opptil 30 dager, korrespondanse opptil 90 dager etter avsluttet sak, minimal rettighetsdokumentasjon 12 måneder med bare dato, type, utfall. Hovedloggen er satt til 30 dager. Gamle SQL-kopier omfatter ikke Firestore; nye kopier og gjenoppretting krever eget oppsett, er ikke automatisk aktive og har 30-dagersgrense ved aktivering. Andre lagre, eksporter og e-post må kontrolleres og konfigureres før publisering. Kopier er for gjenoppretting, ikke gjenbruk av slettede kontoer; gjenta sletting før tilgang etter gjenoppretting. Lovkrav og tvister bare i nødvendig omfang og tid. Firebase oppgir uker for innloggings-IP, andre autentiseringsdata til sletteforespørsel og deretter opptil 180 dager i aktive systemer og kopier. Googles betalinger og måledata har egne regler; OpenAI er beskrevet ovenfor.

## Dine rettigheter

Med vilkårene og unntakene i GDPR kan du be om innsyn, kopi, retting, sletting, begrensning, dataportabilitet, protestere mot berettiget interesse og trekke samtykke uten virkning på tidligere behandling. Kontakt: contact@sedno.xyz; svar uten ugrunnet opphold, normalt innen én måned; lovlig forlengelse med to måneder forklares i første måned. Ved rimelig tvil om identitet bekrefter vi bare det nødvendige, uten rutinemessige ID-dokumenter. Klage: polske UODO, https://uodo.gov.pl. Du trenger ikke sende apptekster for å be om data.

## Endringer

Versjoner har dato. Vesentlige endringer varsles på personvernsiden og i oppdateringsnotater før ny behandling. Dokumentet erstatter ikke nødvendig samtykke. Leverandør, formål og lagringstid må også oppdateres i tjenestens faktiske oppsett.

## Kilder og leverandørvilkår

commission.europa.eu: https://commission.europa.eu/law/law-topic/data-protection/information-business-and-organisations/legal-grounds-processing-data_en

developers.openai.com: https://developers.openai.com/api/docs/guides/your-data

openai.com: https://openai.com/policies/services-agreement/

firebase.google.com: https://firebase.google.com/support/privacy

developers.google.com: https://developers.google.com/ml-kit/android-data-disclosure

cloud.google.com: https://cloud.google.com/terms/google-entity

cloud.google.com: https://cloud.google.com/terms/data-processing-addendum

policies.google.com: https://policies.google.com/privacy/frameworks?hl=en

