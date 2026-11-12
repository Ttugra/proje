# Tasarım notları (sohbetten özet)

## Oyun
Roblox'ta tuğla inşa + satış + büyüme oyunu.
- Oyuncu tezgaha yaklaşınca kamera inşa platformuna geçer, tuğla parçalarla model yapar.
- Model analiz edilip puanlanır ve fiyatlanır, rafa konup NPC müşterilere satılır.
- Garajla başlanır, ilerledikçe yeni mekanlar açılır; platform, parça limiti ve parça çeşidi yükseltmelerle büyür.
- Sunucu başına 6-8 oyuncu (`Config.MAX_PLAYERS = 8`), her oyuncunun kendi plot'u var.
  Oyuncular birbirinin plot'una gidip raftaki modelleri görebilir ama sadece bakabilir.
- Satışlar NPC müşterilerle (oyuncudan oyuncuya satış yok).

## Marka / telif
- Görünüm "kenetlenen plastik tuğla" olabilir ama adda, ikonda, açıklamada, parça adlarında "LEGO" ve logo YOK.
- Stud üstünde yazı/logo yok, minifigür birebir kopya yok, resmi set/lisanslı tema kopyası yok.
- LDraw/LeoCAD (GPL) sadece fikir/ölçü için incelendi; kod veya parça dosyası kopyalanmadı.
- Ciddi gelir hedefleniyorsa yayın öncesi fikri mülkiyet avukatına danış.

## İnşa sistemi (karar: dünyada kamera geçişi)
- ViewportFrame yerine gerçek dünyada kamera geçişi: gerçek ışık, Raycast hazır, daha az kod.
  ViewportFrame sadece raf küçük resimleri / envanter / analiz önizlemesi için.
- Kontroller: yörünge kamera, parça çubuğu, hayalet önizleme (geçersizse kırmızı), R ile 90° döndürme,
  renk paleti, silme, Ctrl+Z / Ctrl+Y, "rafa koy", parça sayacı.
- Server her yerleştirmeyi OccupancyGrid ile doğrular (hile önleme). Client sadece öneri yapar.

## Veri modeli (roblox/src/shared)
- Model = `{id, part, rot(0..3), x, y, z, color}` listesi, tam sayı hücrelerde.
  x,y = stud, z = plaka. Konum = döndürülmüş ayak izinin en düşük köşe hücresi.
- Birimler (LDraw'dan): stud aralığı 20 LDU, plaka 8, tuğla 24 (= 3 plaka).
- Roblox birimine çeviri sadece render'da, `Config.SCALE = 0.01` (1 stud aralığı = 0.2 Roblox stud).
  Ölçü hissi Studio'da gözle ayarlanacak; tek sabit.
- OccupancyGrid doğruluk kaynağı: çakışma, sınır, "havada asılı" (stud bağlantısına göre; düz parçanın üstü bağlanmaz),
  kaydet/yükle (yüklenen veri doğrulanır).
- Stud'lar sadece görsel (mesh'e gömülü), ayrı mantık yok.
- Geri al/yinele: komut yığını, aynı `mergeKey`'li ardışık işlemler tek adımda birleşir.

## Ölçüler
- Başlangıç platformu 12x12 stud (2.4 x 2.4 Roblox stud), adımlar: 12, 16, 24, 32, 48.
- Başlangıç yüksekliği 16 tuğla (48 plaka), parça limiti 300 (yükseltmeyle artar).

## Analiz / fiyat fikri (henüz yazılmadı)
Parça sayısı ve çeşitliliği, renk uyumu, simetri, doluluk, nadir parça, yapısal bütünlük (floatingPieces),
özgünlük (aynı modelden çok varsa değer düşer). Amaç yaratıcılığı ödüllendirmek, anlamsız parça
eklemeyi değil. Talep/trend ve NPC tercihi fiyata rastgelelik katar.

## Mesh'ler
`tools/blender/gen_bricks.py` (bpy, arayüzsüz) 27 parça üretir: brick/plate/tile, 1x1..2x6, FBX, Y-up,
1 Blender birimi = 1 stud aralığı, orijin en düşük köşe. Studio'ya aktarıp orijinin köşede mi merkezde mi
geldiği DOĞRULANMADI.

## Durum
- Yazıldı ama ÇALIŞTIRILMADI: `roblox/tests/run.luau` (Luau CLI ile çalıştırılmadı), Rojo bağlantısı, mesh içe aktarma.
- Yok: client inşa sistemi, tezgah/kamera, plot sistemi, NPC'ler, analiz/fiyat, DataStore.

## Sıradaki adımlar
1. Rojo ile Studio'ya bağlan, Output'ta iki başlangıç satırını doğrula.
2. `luau roblox/tests/run.luau` çalıştır, hataları düzelt.
3. Studio'da test sahnesi: 12x12 platform, birkaç tuğla, karakter ölçeği referansı; SCALE'i gözle ayarla.
4. Mesh'leri içe aktar, orijin/pivot'u doğrula.
5. Client: raycast ile hücre bulma, hayalet parça, yerleştirme, undo/redo, orbit kamera.
6. Server: plot ataması, doğrulama, kaydetme.
7. Analiz/fiyat, raf, NPC müşteri, ziyaret.
