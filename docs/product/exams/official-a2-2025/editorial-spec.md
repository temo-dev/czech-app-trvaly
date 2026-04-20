# Official A2 2025 Editorial Spec

Canonical source for the official-style exam seeded by:
- [20260421000002_official_exam_result_columns.sql](/Users/daniel.dev/Desktop/app-czech/supabase/migrations/20260421000002_official_exam_result_columns.sql:1)
- [20260421000003_seed_official_a2_pdf_exam.sql](/Users/daniel.dev/Desktop/app-czech/supabase/migrations/20260421000003_seed_official_a2_pdf_exam.sql:1)

Supporting assets:
- [asset-manifest.json](/Users/daniel.dev/Desktop/app-czech/docs/product/exams/official-a2-2025/asset-manifest.json:1)
- [generate_official_a2_audio.py](/Users/daniel.dev/Desktop/app-czech/cms/scripts/generate_official_a2_audio.py:1)

## Exam Shape

| Section | App section id | Count | Duration | Notes |
|---|---|---:|---:|---|
| Reading | `bbbbbbbb-2222-0000-0000-000000000001` | 25 | 40 min | Tasks 1–5 |
| Writing | `bbbbbbbb-2222-0000-0000-000000000002` | 2 | 25 min | Official task weights 8 + 12 |
| Listening | `bbbbbbbb-2222-0000-0000-000000000003` | 25 | 40 min | Tasks 1–5 |
| Speaking | `bbbbbbbb-2222-0000-0000-000000000004` | 4 | 15 min | Official task weights 8 + 12 + 10 + 10 |

Official pass rule in app:
- Written bucket = reading + listening + writing = `70` points total, pass at `42`
- Speaking bucket = `40` points total, pass at `24`
- Persisted `exam_results.passed` is based on both buckets, not just percentage

## Asset Inventory

| Kind | Local file(s) | Storage path prefix | Used by |
|---|---|---|---|
| Reading images | `assets/images/reading-task1-q1..q5.png` | `questions/official-a2-2025/` | Reading task 1 |
| Listening option images | `assets/images/listening-task4-option-a..f.png` | `questions/options/official-a2-2025/` | Listening task 4 |
| Speaking intro image | `assets/images/speaking-task3-storyboard.png` | `questions/intro/official-a2-2025/` | Speaking task 3 |
| Speaking intro image | `assets/images/speaking-task4-choices.png` | `questions/intro/official-a2-2025/` | Speaking task 4 |
| Listening audio | `assets/audio/listening-task1-q1..q5.wav` | `questions/audio/official-a2-2025/` | Listening task 1 |
| Listening audio | `assets/audio/listening-task2-q6..q10.wav` | `questions/audio/official-a2-2025/` | Listening task 2 |
| Listening audio | `assets/audio/listening-task3-q11..q15.wav` | `questions/audio/official-a2-2025/` | Listening task 3 |
| Listening audio | `assets/audio/listening-task4-q16..q20.wav` | `questions/audio/official-a2-2025/` | Listening task 4 |
| Listening audio | `assets/audio/listening-task5-message.wav` | `questions/audio/official-a2-2025/` | Listening task 5 |

## Reading

### Task 1

Shared source:
- Official visual prompts only; each item is rendered as `mcq` with a question image.
- Vietnamese explanation is stored in `questions.explanation`.

| App q | Order | Asset | Correct answer | Vietnamese explanation |
|---|---:|---|---|---|
| `20000001-...0001` | 1 | `reading-task1-q1.png` | `D) Balík si můžete vyzvednout u přepážky 3.` | Ảnh là quầy nhận bưu kiện. |
| `20000001-...0002` | 2 | `reading-task1-q2.png` | `B) Příjem na chirurgii od 7:00.` | Ảnh là khoa phẫu thuật. |
| `20000001-...0003` | 3 | `reading-task1-q3.png` | `H) Můžu vás ostříhat dnes v 16:00.` | Ảnh là tiệm cắt tóc. |
| `20000001-...0004` | 4 | `reading-task1-q4.png` | `F) Vaše auto je připravené.` | Ảnh là thông báo nhận xe. |
| `20000001-...0005` | 5 | `reading-task1-q5.png` | `C) Vaše pračka už je opravená.` | Ảnh là thợ sửa máy giặt. |

### Task 2

Shared Czech source text:

```text
Vážení spoluobčané,
všechny Vás zveme na slavnostní otevření nového sportoviště, které se koná dne 25. 6. a kterého se zúčastní také jeho architekt, pan inženýr Kučera. Zároveň oznamujeme, že od 1. 6. je sportoviště v provozu. Stavba trvala od 10. 5. 2023 do 30. 4. 2025.

Sportoviště zahrnuje hřiště na fotbal, volejbalové kurty, hřiště na basketbal a plavecký bazén. V červenci ještě otevřeme tenisové kurty. O sportoviště se budou starat pánové I. Písecký a M. Hulák.

V areálu bude otevřeno každý den od 8:00 do 20:00 hodin od května do září a od 9:00 do 18:00 hodin v dubnu a v říjnu. Od listopadu do března bude areál uzavřený. Pozor, bazén bude otevřen pouze v létě.

Všichni uživatelé si musí rezervovat dobu návštěvy přes on-line systém a také zaplatit poplatek. Individuální sportovci z naší obce platí 150 Kč/h, občané z okolních obcí 200 Kč/h, za klubové sportovce platí jejich kluby. Poplatky neplatí pouze školy.

Otevřením sportoviště naše práce nekončí. Máme ještě v plánu vybudovat saunu a fitness centrum.

Petr Smažík, starosta
```

| App q | Order | Czech prompt | Correct answer | Vietnamese explanation |
|---|---:|---|---|---|
| `...0006` | 6 | `Kdy skončila stavba sportoviště?` | `30. 4. 2025` option | Công trình kết thúc ngày 30. 4. 2025. |
| `...0007` | 7 | `Kdy můžete jít na fotbalové hřiště v měsíci říjnu?` | `9:00–18:00` option | Tháng 10 mở 9:00–18:00. |
| `...0008` | 8 | `Ve kterém měsíci bude celý areál zavřený?` | `prosinec` option | Từ tháng 11 đến tháng 3 khu này đóng cửa. |
| `...0009` | 9 | `Pro koho je sportoviště zadarmo?` | `pro školy` option | Chỉ trường học không trả phí. |
| `...0010` | 10 | `Co chce obec ještě postavit?` | `saunu` option | Phần cuối báo còn xây sauna và fitness. |

### Task 3

Shared Czech source text:

```text
A) Mariya: dvě malé děti, mluví dobře česky, potřebuje poradit s hledáním práce.
B) Iva: skončila střední školu v ČR, baví ji móda a chce mít živnost.
C) Lada: pracovala jako vedoucí IT oddělení a chce doplnit vzdělání.
D) Ria: přijela s dcerou, rády pečou a chce vařit v restauraci.
E) Anton: inženýr, hledá práci v německé firmě a potřebuje němčinu.
F) Bao: byla dlouho v domácnosti, je jí 56 let a potřebuje základy práce s počítačem.
```

| App q | Order | Offer mapping | Correct answer | Vietnamese explanation |
|---|---:|---|---|---|
| `...0011` | 11 | `Kurz pro pokročilé informatiky` | `C) Lada` | Lada làm IT và muốn học nâng cao. |
| `...0012` | 12 | `Kurzy němčiny pro mírně a středně pokročilé` | `E) Anton` | Anton cần tiếng Đức cho công việc. |
| `...0013` | 13 | `Poradenství práce + dětský klub` | `A) Mariya` | Mariya cần tìm việc và trông con. |
| `...0014` | 14 | `Kurz vaření se šéfkuchařem` | `D) Ria` | Ria muốn nấu ăn chuyên nghiệp. |

### Task 4

| App q | Order | Czech prompt | Correct answer | Vietnamese explanation |
|---|---:|---|---|---|
| `...0015` | 15 | `prodej a rezervaci jízdenek pro _________` | `vnitrostátní` | Nghĩa là vận tải nội địa. |
| `...0016` | 16 | `U nás vám _________ pomůžeme.` | `rádi` | Cụm chuẩn là `rádi pomůžeme`. |
| `...0017` | 17 | `Do nově otevřené restaurace _________ kuchaře/kuchařku.` | `přijmeme` | Động từ tuyển dụng đúng là `přijmeme`. |
| `...0018` | 18 | `Nakupujte v našem novém _________` | `pekařství` | Ngữ cảnh là tiệm bánh. |
| `...0019` | 19 | `nový běžný _________` | `účet` | `běžný účet` là tài khoản ngân hàng thường. |
| `...0020` | 20 | `u náměstí _________ byt ve druhém patře.` | `hořel` | Ngữ cảnh cháy nhà dùng `hořel`. |

### Task 5

Shared Czech source text:

```text
Bramborový salát z Pohořelic

Na tento bramborový salát budete potřebovat:
1 kg vařených brambor, 4 vajíčka, 1 velkou cibuli, 1 lžíci hořčice, 1 lžíci oleje, ne olivového, 4 kyselé okurky, 1 větší mrkev, 1 sklenici majonézy.

Příprava:
1. Brambory uvaříme den předem.
2. Cibuli nakrájíme nadrobno.
3. Vejce uvaříme natvrdo a přidáme k cibuli a bramborům.
4. Mrkev uvaříme a spolu s okurkami nakrájíme a přidáme do salátu.
5. Nakonec přidáme olej, pepř, sůl, hořčici a majonézu.
6. Vše dobře promícháme a servírujeme, nejlépe s řízkem nebo rybou.
```

| App q | Order | Czech prompt | Primary answer | Accepted answers | Vietnamese explanation |
|---|---:|---|---|---|---|
| `...0021` | 21 | `můžeme připravit _________ salát` | `bramborový` | `bramborovy` | Tên món nằm ngay đầu bài. |
| `...0022` | 22 | `potřebujeme jednu _________ cibuli` | `velkou` | `velká` | Trong nguyên liệu có `1 velkou cibuli`. |
| `...0023` | 23 | `není vhodné použít olivový _________` | `olej` | `oleje` | Công thức ghi `ne olivového`. |
| `...0024` | 24 | `Brambory uvaříme 1 _________ před přípravou` | `den` | `jeden den` | `den předem`. |
| `...0025` | 25 | `nejlépe hodí řízek nebo _________` | `rybou` | `ryba` | Câu cuối ghi `řízkem nebo rybou`. |

## Writing

| App q | Order | Official task | Points | Czech source / rubric | Vietnamese explanation |
|---|---:|---|---:|---|---|
| `30000001-...0001` | 1 | `ÚLOHA 1 – Formulář` | 8 | Three short answers for `Maxi-drogerie.cz`, min 10 words each, Czech only | App stores full official rubric in `correct_answer` and model hints in `explanation`. |
| `30000001-...0002` | 2 | `ÚLOHA 2 – E-mail` | 12 | Greeting + 5 required points, min 35 words, Czech only | App uses one long-form writing submission with full prompt and AI rubric. |

## Listening

### Task 1

Shared mapping:
- Five short dialogues, each rendered as one `mcq`.
- Audio assets are generated from the Czech transcript and played twice in the TTS clip.

| App q | Order | Audio | Czech source summary | Correct answer | Vietnamese explanation |
|---|---:|---|---|---|---|
| `...0001` | 1 | `listening-task1-q1.wav` | route to station | `A) Trolejbusem.` | Người phụ nữ chỉ trolejbus số 4. |
| `...0002` | 2 | `listening-task1-q2.wav` | weekend invitation | `A) Do muzea.` | Chủ nhật Ludvík đi bảo tàng. |
| `...0003` | 3 | `listening-task1-q3.wav` | garden / house discussion | `B) Auto.` | Irena nói cần mua ô tô trước. |
| `...0004` | 4 | `listening-task1-q4.wav` | parcel pickup | `C) V kanceláři.` | Martin còn ở văn phòng. |
| `...0005` | 5 | `listening-task1-q5.wav` | hospital directions | `D) Na rehabilitaci.` | Anh ấy đi phục hồi chức năng. |

### Task 2

| App q | Order | Audio | Czech source summary | Correct answer | Vietnamese explanation |
|---|---:|---|---|---|---|
| `...0006` | 6 | `listening-task2-q6.wav` | supermarket announcement | `C) 13 %.` | Thịt heo giảm 13%. |
| `...0007` | 7 | `listening-task2-q7.wav` | language school schedule | `B) Pro mírně pokročilé.` | Thứ Ba là lớp hơi nâng cao. |
| `...0008` | 8 | `listening-task2-q8.wav` | bus route change | `C) Do města Louny.` | Chuyến 9 giờ bỏ điểm Louny. |
| `...0009` | 9 | `listening-task2-q9.wav` | restaurant hiring | `B) 30 000 Kč.` | Lương cơ bản phục vụ là 30k Kč. |
| `...0010` | 10 | `listening-task2-q10.wav` | weather forecast | `C) V sobotu v noci.` | -10 °C trên núi vào đêm thứ Bảy. |

### Task 3

Shared Czech source summary:
- Leila → photographing
- Džamila → drawing
- Ivona → reading
- Hindi → swimming
- Naďa → cooking

| App q | Order | Audio | Correct answer | Vietnamese explanation |
|---|---:|---|---|---|
| `...0011` | 11 | `listening-task3-q11.wav` | `G) fotografování` | Leila chụp ảnh thiên nhiên. |
| `...0012` | 12 | `listening-task3-q12.wav` | `C) kreslení` | Džamila vẫn vẽ tranh. |
| `...0013` | 13 | `listening-task3-q13.wav` | `E) čtení` | Ivona đọc sách. |
| `...0014` | 14 | `listening-task3-q14.wav` | `F) plavání` | Hindi bơi mỗi ngày. |
| `...0015` | 15 | `listening-task3-q15.wav` | `B) vaření` | Naďa thích nấu ăn nhất. |

### Task 4

Shared source:
- Official image-choice set cropped to `listening-task4-option-a..f.png`.
- Each app question is one `mcq` with image options in `question_options.image_url`.

| App q | Order | Audio | Correct option | Vietnamese explanation |
|---|---:|---|---|---|
| `...0016` | 16 | `listening-task4-q16.wav` | `F` | Người phụ nữ chọn áo thun trắng. |
| `...0017` | 17 | `listening-task4-q17.wav` | `A` | Câu về găng tay map sang hình A. |
| `...0018` | 18 | `listening-task4-q18.wav` | `D` | Người đàn ông cần cà vạt. |
| `...0019` | 19 | `listening-task4-q19.wav` | `B` | Cô ấy cần váy hồng dự đám cưới. |
| `...0020` | 20 | `listening-task4-q20.wav` | `C` | Cần áo khoác mùa đông size L/XL. |

### Task 5

Shared Czech transcript:

```text
Ahoj Lído, tady Eva. Lído, dostala jsem od své sestry Ivany k narozeninám dva lístky na balet. Ivana nemůže a já nechci jít sama. Nechceš jít se mnou? Vím, že máš balet moc ráda. Představení je ve čtvrtek dvacátého osmého dubna v Národním divadle. Začátek je v šest hodin večer. Potom můžeme jít na večeři. Znám jednu dobrou restauraci, jmenuje se Klášterní. Ozvi se mi prosím do středy do večera na telefon sedm sedm tři devět tři dva pět nula čtyři. Budu se těšit, ahoj.
```

| App q | Order | Audio | Primary answer | Accepted answers | Vietnamese explanation |
|---|---:|---|---|---|---|
| `...0021` | 21 | `listening-task5-message.wav` | `Eva` | `eva` | Người gọi tự giới thiệu là Eva. |
| `...0022` | 22 | `listening-task5-message.wav` | `čtvrtek` | `Čtvrtek`, `ctvrtek` | Buổi ballet vào thứ Năm. |
| `...0023` | 23 | `listening-task5-message.wav` | `28. dubna` | `28. 4.`, `28 dubna`, `dvacátého osmého dubna` | Ngày 28 tháng 4. |
| `...0024` | 24 | `listening-task5-message.wav` | `Klášterní` | `klášterní`, `Klasterni` | Nhà hàng tên Klášterní. |
| `...0025` | 25 | `listening-task5-message.wav` | `932 504` | `932504`, `773932504`, `773 932 504` | Đề chỉ yêu cầu phần sau `773`. |

## Speaking

| App q | Order | Official task | Points | Asset | Czech source / rubric | Vietnamese explanation |
|---|---:|---|---:|---|---|---|
| `50000001-...0001` | 1 | `ÚLOHA 1 – Odpovědi na otázky` | 8 | — | 8 guided questions across `Život v České republice` + `Počasí` | Trả lời đủ 8 câu bằng câu đầy đủ, rõ ràng. |
| `50000001-...0002` | 2 | `ÚLOHA 2 – Dialogy` | 12 | — | Two role-play cards: shoes + apartment rental | Cần hỏi đủ các ý và thêm 1 câu mở rộng cho mỗi thẻ. |
| `50000001-...0003` | 3 | `ÚLOHA 3 – Vyprávění podle obrázků` | 10 | `speaking-task3-storyboard.png` | 4-picture story about buying a TV; use past tense | Kể đúng trình tự 4 tranh, dùng quá khứ. |
| `50000001-...0004` | 4 | `ÚLOHA 4 – Řešení situace` | 10 | `speaking-task4-choices.png` | choose 1 place from the image; rubric explicitly splits `7 + 3` | 7 điểm nội dung + 3 điểm phát âm/fonetics. |

## Operational Notes

- Objective reading/listening items remain `type='mcq'` or `type='fill_blank'` with `skill='reading'|'listening'`.
- `correct_answer` is the display answer; `accepted_answers` supports tolerant fill-blank grading.
- `intro_text`, `intro_image_url`, and `passage_text` are authored directly for runtime use; no more prompt overloading for passages.
- `asset-manifest.json` is the upload contract. The storage paths must stay in sync with the URLs hardcoded in the seed migration.
