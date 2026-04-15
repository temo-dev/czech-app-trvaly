-- =============================================================================
-- Seed: Mock exam questions + options
-- Exam: "Bài thi thử Trvalý pobyt" (id: 00000000-0000-0000-0000-000000000001)
-- Sections:
--   Reading  → 963af233-a7f0-4509-b4ba-0a749297c36d (10 câu)
--   Listening→ 45625d56-5030-4007-a5e5-d0af1e83a0c1 (10 câu)
--   Writing  → 7b4f3849-6e06-47d6-a390-7fefd5d4cb27  (5 câu)
--   Speaking → 9d16683d-84fd-49dc-8203-358a4b2b88b2   (5 câu)
-- UUID prefix: 00000001=reading, 00000002=listening, 00000003=writing, 00000004=speaking
-- =============================================================================

-- ── READING questions (MCQ) ───────────────────────────────────────────────────

INSERT INTO questions (id, section_id, type, skill, prompt, correct_answer, explanation, points, order_index) VALUES
('00000001-0000-0000-0000-000000000001','963af233-a7f0-4509-b4ba-0a749297c36d','mcq','reading',
 'Přečtěte si větu: "Dnes je hezké počasí. Slunce svítí a je teplo." Co je dnes za počasí?',
 'a','Text říká: slunce svítí a je teplo — jde o hezké, slunečné počasí.',1,1),
('00000001-0000-0000-0000-000000000002','963af233-a7f0-4509-b4ba-0a749297c36d','mcq','reading',
 'Přečtěte si: "Nemocnice se nachází blízko náměstí, vedle pošty." Kde je nemocnice?',
 'b','Blízko náměstí, vedle pošty = near the square, next to the post office.',1,2),
('00000001-0000-0000-0000-000000000003','963af233-a7f0-4509-b4ba-0a749297c36d','mcq','reading',
 'Co znamená výraz "průkaz totožnosti"?',
 'c','Průkaz totožnosti je doklad prokazující totožnost osoby — např. občanský průkaz nebo pas.',1,3),
('00000001-0000-0000-0000-000000000004','963af233-a7f0-4509-b4ba-0a749297c36d','mcq','reading',
 'Přečtěte si oznámení: "Úřad je otevřen v pondělí až pátek od 8 do 17 hodin." Kdy je úřad zavřen?',
 'd','Úřad je otevřen od pondělí do pátku, tedy o víkendu (sobota, neděle) je zavřen.',1,4),
('00000001-0000-0000-0000-000000000005','963af233-a7f0-4509-b4ba-0a749297c36d','mcq','reading',
 'Přečtěte si: "Jana pracuje jako zdravotní sestra v nemocnici." Kde pracuje Jana?',
 'a','Jana pracuje v nemocnici jako zdravotní sestra.',1,5),
('00000001-0000-0000-0000-000000000006','963af233-a7f0-4509-b4ba-0a749297c36d','mcq','reading',
 'Co znamená slovo "jídelna"?',
 'b','Jídelna = dining room / canteen — místnost nebo prostor určený k jídlu.',1,6),
('00000001-0000-0000-0000-000000000007','963af233-a7f0-4509-b4ba-0a749297c36d','mcq','reading',
 'Přečtěte si: "Vlak odjíždí v 8:30 z nástupiště číslo 3." Odkud vlak odjíždí?',
 'c','Vlak odjíždí z nástupiště číslo 3 — platform number 3.',1,7),
('00000001-0000-0000-0000-000000000008','963af233-a7f0-4509-b4ba-0a749297c36d','mcq','reading',
 'Přečtěte si: "Petr bydlí v Praze, ale pochází z Brna." Odkud Petr pochází?',
 'b','Petr pochází z Brna, i když nyní bydlí v Praze.',1,8),
('00000001-0000-0000-0000-000000000009','963af233-a7f0-4509-b4ba-0a749297c36d','mcq','reading',
 'Co znamená "trvalý pobyt"?',
 'd','Trvalý pobyt = permanent residence — trvalé bydliště nebo oprávnění dlouhodobě žít v zemi.',1,9),
('00000001-0000-0000-0000-000000000010','963af233-a7f0-4509-b4ba-0a749297c36d','mcq','reading',
 'Přečtěte si: "Děti jdou do školy každý den kromě soboty a neděle." Kdy děti nejdou do školy?',
 'a','Děti nejdou do školy v sobotu a neděli — o víkendu.',1,10);

INSERT INTO question_options (question_id, text, is_correct, order_index) VALUES
-- q1: correct=a
('00000001-0000-0000-0000-000000000001','Slunečno a teplo',true,1),
('00000001-0000-0000-0000-000000000001','Zataženo a chladno',false,2),
('00000001-0000-0000-0000-000000000001','Sněhová bouře',false,3),
('00000001-0000-0000-0000-000000000001','Deštivo a větrno',false,4),
-- q2: correct=b
('00000001-0000-0000-0000-000000000002','Daleko od centra, u nádraží',false,1),
('00000001-0000-0000-0000-000000000002','Blízko náměstí, vedle pošty',true,2),
('00000001-0000-0000-0000-000000000002','Na druhém konci města',false,3),
('00000001-0000-0000-0000-000000000002','Přímo na náměstí',false,4),
-- q3: correct=c
('00000001-0000-0000-0000-000000000003','Jízdenka na autobus',false,1),
('00000001-0000-0000-0000-000000000003','Průkaz do práce',false,2),
('00000001-0000-0000-0000-000000000003','Doklad prokazující totožnost',true,3),
('00000001-0000-0000-0000-000000000003','Studentský průkaz',false,4),
-- q4: correct=d
('00000001-0000-0000-0000-000000000004','Každý den od 17 hodin',false,1),
('00000001-0000-0000-0000-000000000004','V pátek odpoledne',false,2),
('00000001-0000-0000-0000-000000000004','Každý den ráno',false,3),
('00000001-0000-0000-0000-000000000004','O víkendu (sobota a neděle)',true,4),
-- q5: correct=a
('00000001-0000-0000-0000-000000000005','V nemocnici',true,1),
('00000001-0000-0000-0000-000000000005','V lékárně',false,2),
('00000001-0000-0000-0000-000000000005','Ve škole',false,3),
('00000001-0000-0000-0000-000000000005','V úřadě',false,4),
-- q6: correct=b
('00000001-0000-0000-0000-000000000006','Obývací pokoj',false,1),
('00000001-0000-0000-0000-000000000006','Místnost nebo prostor určený k jídlu',true,2),
('00000001-0000-0000-0000-000000000006','Kuchyně pro vaření',false,3),
('00000001-0000-0000-0000-000000000006','Spíž na potraviny',false,4),
-- q7: correct=c
('00000001-0000-0000-0000-000000000007','Z hlavního nádraží',false,1),
('00000001-0000-0000-0000-000000000007','Z nástupiště číslo 1',false,2),
('00000001-0000-0000-0000-000000000007','Z nástupiště číslo 3',true,3),
('00000001-0000-0000-0000-000000000007','Z autobusového nádraží',false,4),
-- q8: correct=b
('00000001-0000-0000-0000-000000000008','Z Prahy',false,1),
('00000001-0000-0000-0000-000000000008','Z Brna',true,2),
('00000001-0000-0000-0000-000000000008','Z Ostravy',false,3),
('00000001-0000-0000-0000-000000000008','Z Plzně',false,4),
-- q9: correct=d
('00000001-0000-0000-0000-000000000009','Krátkodobé vízum',false,1),
('00000001-0000-0000-0000-000000000009','Turistická dovolená',false,2),
('00000001-0000-0000-0000-000000000009','Pracovní povolení',false,3),
('00000001-0000-0000-0000-000000000009','Trvalé bydliště nebo oprávnění žít v zemi',true,4),
-- q10: correct=a
('00000001-0000-0000-0000-000000000010','O víkendu — v sobotu a neděli',true,1),
('00000001-0000-0000-0000-000000000010','Ve středu',false,2),
('00000001-0000-0000-0000-000000000010','Každý den odpoledne',false,3),
('00000001-0000-0000-0000-000000000010','V pátek',false,4);


-- ── LISTENING questions (MCQ) ─────────────────────────────────────────────────

INSERT INTO questions (id, section_id, type, skill, prompt, correct_answer, explanation, points, order_index) VALUES
('00000002-0000-0000-0000-000000000001','45625d56-5030-4007-a5e5-d0af1e83a0c1','mcq','listening',
 '[Poslech] Muž říká: "Promiňte, kde je nejbližší zastávka autobusu?" Co hledá muž?',
 'b','Muž hledá nejbližší zastávku autobusu — bus stop.',1,1),
('00000002-0000-0000-0000-000000000002','45625d56-5030-4007-a5e5-d0af1e83a0c1','mcq','listening',
 '[Poslech] Žena říká: "Chtěla bych si zarezervovat stůl pro dvě osoby na pátek večer." Co žena chce?',
 'a','Žena chce rezervovat stůl pro dvě osoby na pátek večer.',1,2),
('00000002-0000-0000-0000-000000000003','45625d56-5030-4007-a5e5-d0af1e83a0c1','mcq','listening',
 '[Poslech] Hlasatel říká: "Příští vlak do Brna odjíždí v 14:45 z nástupiště 5." Kdy odjíždí vlak?',
 'c','Vlak odjíždí ve čtvrt na tři odpoledne — 14:45.',1,3),
('00000002-0000-0000-0000-000000000004','45625d56-5030-4007-a5e5-d0af1e83a0c1','mcq','listening',
 '[Poslech] Doktor říká: "Vezměte si jednu tabletu třikrát denně po jídle." Jak often se bere lék?',
 'd','Třikrát denně = three times a day — ráno, v poledne a večer, po jídle.',1,4),
('00000002-0000-0000-0000-000000000005','45625d56-5030-4007-a5e5-d0af1e83a0c1','mcq','listening',
 '[Poslech] Prodavačka říká: "Obchod je zavřený v neděli a ve svátky." Kdy je obchod zavřený?',
 'b','Obchod je zavřený o nedělích a státních svátcích.',1,5),
('00000002-0000-0000-0000-000000000006','45625d56-5030-4007-a5e5-d0af1e83a0c1','mcq','listening',
 '[Poslech] Muž říká: "Hledám práci v oblasti IT. Mám pět let zkušeností." Co muž hledá?',
 'a','Muž hledá práci v oblasti informačních technologií.',1,6),
('00000002-0000-0000-0000-000000000007','45625d56-5030-4007-a5e5-d0af1e83a0c1','mcq','listening',
 '[Poslech] Úřednice říká: "Prosím, vyplňte tento formulář a přineste ho zpět na přepážku číslo tři." Co musíte udělat?',
 'c','Vyplnit formulář a přinést ho na přepážku číslo 3.',1,7),
('00000002-0000-0000-0000-000000000008','45625d56-5030-4007-a5e5-d0af1e83a0c1','mcq','listening',
 '[Poslech] Žena říká: "Ráda bych prodloužila povolení k pobytu." Co chce žena prodloužit?',
 'd','Povolení k pobytu = residence permit.',1,8),
('00000002-0000-0000-0000-000000000009','45625d56-5030-4007-a5e5-d0af1e83a0c1','mcq','listening',
 '[Poslech] Meteorolog říká: "Dnes bude oblačno s přeháňkami, teplota kolem 15 stupňů." Jaké bude počasí?',
 'b','Oblačno s přeháňkami, teplota přibližně 15 °C.',1,9),
('00000002-0000-0000-0000-000000000010','45625d56-5030-4007-a5e5-d0af1e83a0c1','mcq','listening',
 '[Poslech] Zpráva: "Autobus číslo 22 nejezdí kvůli opravám do konce měsíce." Proč autobus nejezdí?',
 'a','Autobus nejezdí kvůli opravám — repairs/maintenance.',1,10);

INSERT INTO question_options (question_id, text, is_correct, order_index) VALUES
-- l1: correct=b
('00000002-0000-0000-0000-000000000001','Nejbližší obchod',false,1),
('00000002-0000-0000-0000-000000000001','Nejbližší zastávku autobusu',true,2),
('00000002-0000-0000-0000-000000000001','Nejbližší restauraci',false,3),
('00000002-0000-0000-0000-000000000001','Nejbližší nemocnici',false,4),
-- l2: correct=a
('00000002-0000-0000-0000-000000000002','Rezervovat stůl pro dvě osoby na pátek večer',true,1),
('00000002-0000-0000-0000-000000000002','Objednat jídlo domů',false,2),
('00000002-0000-0000-0000-000000000002','Koupit lístky na koncert',false,3),
('00000002-0000-0000-0000-000000000002','Zaplatit účet v restauraci',false,4),
-- l3: correct=c
('00000002-0000-0000-0000-000000000003','Ve 14:15',false,1),
('00000002-0000-0000-0000-000000000003','Ve 14:30',false,2),
('00000002-0000-0000-0000-000000000003','Ve 14:45',true,3),
('00000002-0000-0000-0000-000000000003','Ve 15:00',false,4),
-- l4: correct=d
('00000002-0000-0000-0000-000000000004','Jednou denně ráno',false,1),
('00000002-0000-0000-0000-000000000004','Dvakrát denně',false,2),
('00000002-0000-0000-0000-000000000004','Jednou týdně',false,3),
('00000002-0000-0000-0000-000000000004','Třikrát denně po jídle',true,4),
-- l5: correct=b
('00000002-0000-0000-0000-000000000005','Každý den od 20 hodin',false,1),
('00000002-0000-0000-0000-000000000005','V neděli a ve svátky',true,2),
('00000002-0000-0000-0000-000000000005','V sobotu odpoledne',false,3),
('00000002-0000-0000-0000-000000000005','Každé ráno',false,4),
-- l6: correct=a
('00000002-0000-0000-0000-000000000006','Práci v oblasti IT',true,1),
('00000002-0000-0000-0000-000000000006','Byt k pronájmu',false,2),
('00000002-0000-0000-0000-000000000006','Kurz češtiny',false,3),
('00000002-0000-0000-0000-000000000006','Auto na prodej',false,4),
-- l7: correct=c
('00000002-0000-0000-0000-000000000007','Zaplatit poplatek online',false,1),
('00000002-0000-0000-0000-000000000007','Počkat v čekárně',false,2),
('00000002-0000-0000-0000-000000000007','Vyplnit formulář a přinést na přepážku číslo 3',true,3),
('00000002-0000-0000-0000-000000000007','Zavolat na úřad',false,4),
-- l8: correct=d
('00000002-0000-0000-0000-000000000008','Řidičský průkaz',false,1),
('00000002-0000-0000-0000-000000000008','Pracovní smlouvu',false,2),
('00000002-0000-0000-0000-000000000008','Cestovní pas',false,3),
('00000002-0000-0000-0000-000000000008','Povolení k pobytu',true,4),
-- l9: correct=b
('00000002-0000-0000-0000-000000000009','Slunečno, 25 °C',false,1),
('00000002-0000-0000-0000-000000000009','Oblačno s přeháňkami, 15 °C',true,2),
('00000002-0000-0000-0000-000000000009','Sněhová bouře, -5 °C',false,3),
('00000002-0000-0000-0000-000000000009','Jasno, 30 °C',false,4),
-- l10: correct=a
('00000002-0000-0000-0000-000000000010','Kvůli opravám do konce měsíce',true,1),
('00000002-0000-0000-0000-000000000010','Kvůli nehodě',false,2),
('00000002-0000-0000-0000-000000000010','Kvůli stávce řidičů',false,3),
('00000002-0000-0000-0000-000000000010','Kvůli bouřce',false,4);


-- ── WRITING questions (open text, no options) ─────────────────────────────────

INSERT INTO questions (id, section_id, type, skill, prompt, correct_answer, explanation, points, order_index) VALUES
('00000003-0000-0000-0000-000000000001','7b4f3849-6e06-47d6-a390-7fefd5d4cb27','writing','writing',
 'Napište krátký dopis (50–80 slov) svému sousedovi. Pozvěte ho na narozeninovou oslavu v sobotu ve 18 hodin u vás doma. Uveďte, co bude k jídlu a co si má přinést.',
 null,'Hodnotí se: správná struktura dopisu, pozvání s časem a místem, zmínka o jídle a přínosu hosta.',2,1),
('00000003-0000-0000-0000-000000000002','7b4f3849-6e06-47d6-a390-7fefd5d4cb27','writing','writing',
 'Napište email na úřad (50–80 slov). Žádáte o informaci, jaké doklady potřebujete pro prodloužení povolení k trvalému pobytu a kdy je úřad otevřen.',
 null,'Hodnotí se: formální styl, jasná žádost o informace (doklady + otevírací hodiny), pozdrav a rozloučení.',2,2),
('00000003-0000-0000-0000-000000000003','7b4f3849-6e06-47d6-a390-7fefd5d4cb27','writing','writing',
 'Popište svůj typický pracovní den (60–80 slov). Uveďte, kdy vstáváte, jak se dostáváte do práce, co děláte během dne a jak trávíte večer.',
 null,'Hodnotí se: chronologická struktura, časové výrazy (ráno, odpoledne, večer), správné tvary sloves.',2,3),
('00000003-0000-0000-0000-000000000004','7b4f3849-6e06-47d6-a390-7fefd5d4cb27','writing','writing',
 'Napište inzerát (40–60 slov) na pronájem bytu. Uveďte velikost bytu, lokalitu, cenu a kontakt.',
 null,'Hodnotí se: stručnost a jasnost inzerátu, uvedení všech klíčových informací.',2,4),
('00000003-0000-0000-0000-000000000005','7b4f3849-6e06-47d6-a390-7fefd5d4cb27','writing','writing',
 'Napište recenzi restaurace (50–70 slov), ve které jste nedávno jedli. Popište jídlo, obsluhu, atmosféru a zda byste restauraci doporučili.',
 null,'Hodnotí se: popis zážitku, vyjádření názoru, přídavná jména a hodnotící výrazy.',2,5);


-- ── SPEAKING questions (no options) ──────────────────────────────────────────

INSERT INTO questions (id, section_id, type, skill, prompt, correct_answer, explanation, points, order_index) VALUES
('00000004-0000-0000-0000-000000000001','9d16683d-84fd-49dc-8203-358a4b2b88b2','speaking','speaking',
 'Představte se. Řekněte své jméno, odkud pocházíte, kde nyní žijete, co děláte a proč jste přišli do České republiky. (1–2 minuty)',
 null,'Hodnotí se: plynulost, výslovnost, gramatická správnost, obsah — jméno, původ, bydliště, zaměstnání, důvod příchodu.',2,1),
('00000004-0000-0000-0000-000000000002','9d16683d-84fd-49dc-8203-358a4b2b88b2','speaking','speaking',
 'Popište obrázek: Na obrázku vidíte rodinu u večeře doma. Popište, co lidé dělají, kde sedí, co jedí a jaká je atmosféra. (1–2 minuty)',
 null,'Hodnotí se: popis prostředí a osob, přítomný čas, slovní zásoba (rodina, jídlo).',2,2),
('00000004-0000-0000-0000-000000000003','9d16683d-84fd-49dc-8203-358a4b2b88b2','speaking','speaking',
 'Vysvětlete: Proč je důležité umět česky v České republice? Uveďte alespoň tři důvody. (1–2 minuty)',
 null,'Hodnotí se: logická argumentace, vyjádření a zdůvodnění názoru, spojovací výrazy (protože, aby, proto).',2,3),
('00000004-0000-0000-0000-000000000004','9d16683d-84fd-49dc-8203-358a4b2b88b2','speaking','speaking',
 'Popište své město nebo obec, kde žijete. Co se vám líbí, co by se mohlo zlepšit a jaké jsou možnosti pro volný čas. (1–2 minuty)',
 null,'Hodnotí se: popis místa, kladné i záporné hodnocení, podmiňovací způsob.',2,4),
('00000004-0000-0000-0000-000000000005','9d16683d-84fd-49dc-8203-358a4b2b88b2','speaking','speaking',
 'Zavolejte na úřad a zeptejte se, jaké dokumenty potřebujete k podání žádosti o trvalý pobyt a jaké jsou poplatky. (simulace telefonního rozhovoru, 1–2 minuty)',
 null,'Hodnotí se: formální styl, jasné otázky, telefonní etiketa (pozdrav, představení, poděkování).',2,5);
