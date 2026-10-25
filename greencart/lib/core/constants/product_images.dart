/// Gambar produk yang tersedia sebagai aset lokal (dipakai pada form penjual).
const productImageAssets = <String>[
  'selada-hijau', 'bayam', 'kangkung', 'sawi-hijau', 'wortel', 'tomat', 'kentang',
  'cabai-merah', 'cabai-rawit', 'bawang-merah', 'jahe', 'serai', 'pisang', 'jeruk',
  'pepaya', 'jagung-manis', 'singkong', 'telur-ayam',
];

String productImagePath(String slug) => 'assets/images/products/$slug.png';
