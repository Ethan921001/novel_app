import 'book.dart';

List<Character> character1 = [ // 重生之我在成大資工當電神
  Character(name: '楊過', description: '男主角，性格倔強癲狂，愛恨分明，武功絕頂'),
  Character(name: '小龍女', description: '女主角，冷若冰霜，出塵脫俗，對楊過情深不悔'),
  Character(name: '郭靖', description: '楊過義父，為人忠厚正直，是《射鵰英雄傳》主角之一'),
];

List<Character> character2 = [ // 水滸全傳
  Character(name: '宋江', description: '呼保義，忠義堂首領，智謀過人'),
  Character(name: '魯智深', description: '花和尚，性格豪爽，力大無窮'),
  Character(name: '林沖', description: '豹子頭，原為八百里分麾下的教頭，武藝高強'),
];

List<Character> character3 = [ // 金瓶梅詞話
  Character(name: '西門慶', description: '富商，風流成性，小說主線圍繞其生活展開'),
  Character(name: '潘金蓮', description: '西門慶的第五房妻，原武大郎之妻，美艷聰明但心機深重'),
  Character(name: '李瓶兒', description: '西門慶的妾室之一，溫柔嫻靜，命運悲慘'),
];

List<Character> character4 = [ // 三國演義
  Character(name: '劉備', description: '三國演義角色'),
  Character(name: '關羽', description: '三國演義角色'),
  Character(name: '張飛', description: '三國演義角色'),
];

List<Character> character5 = [ // 西遊記
  Character(name: '孫悟空', description: '西遊記角色'),
  Character(name: '豬八戒', description: '西遊記角色'),
  Character(name: '沙悟淨', description: '西遊記角色'),
  Character(name: '唐三藏', description: '西遊記角色'),
  Character(name: '白龍馬', description: '西遊記角色'),
];

List<Character> character6 = [ // 台北人
  Character(name: '鄧麗如', description: '出自〈永遠的尹雪艷〉，上海名媛，情感糾葛複雜'),
  Character(name: '尹雪艷', description: '永遠的尹雪艷〉女主角，風情萬種但命運多舛'),
  Character(name: '朱啟銘', description: '出自〈一把青〉，空軍軍官，經歷戰亂與離散'),
];

List<Character> character7 = [ // 半生緣
  Character(name: '顧曼楨', description: '溫柔堅毅的女子，與世鈞有一段曲折的愛情'),
  Character(name: '沈世鈞', description: '出身書香世家，顧曼楨的戀人，卻因家庭與時代所困'),
  Character(name: '顧曼璐', description: '曼楨的姊姊，為了家庭犧牲自己，命運悲劇'),
];

List<Character> character8 = [ // 將軍族
  Character(name: '張將軍', description: '主人公，國民黨退役高級軍官，隨政府遷台後日漸落魄'),
  Character(name: '張太太', description: '張將軍的妻子，曾經風光，如今與丈夫相依為命，堅忍而保守'),
  Character(name: '年輕軍官（敘述者）', description: '故事的敘述者，對將軍一家帶著同情與觀察，象徵新一代的冷眼旁觀'),
];

List<Character> character9 = [ // 紅樓夢
  Character(name: '賈寶玉', description: '小說男主角，感情細膩，叛逆不羈，與林黛玉情深'),
  Character(name: '林黛玉', description: '女主角之一，聰慧多才，體弱多病，個性孤傲'),
  Character(name: '薛寶釵', description: '女主角之一，穩重圓融，容貌端莊，與賈寶玉成婚'),
];

List<Character> character10 = [ // 三體
  Character(name: '葉文潔', description: '天體物理學家，因人生絕望而向外星文明發出訊號'),
  Character(name: '汪淼', description: '奈米材料科學家，捲入地外文明與地球勢力的衝突'),
  Character(name: '羅輯', description: '社會學家，成為關鍵的「面壁者」，深具戰略頭腦'),
];


final List<Book> books = [
  Book("神鵰俠侶", "金庸",  "1959/05/20", 888888, 99999, 'assets/books/book0','assets/images/book0.jpg',character1),
  Book("水滸全傳", "施耐庵", "1589/??/??", 100000, 100000,'assets/books/book1','assets/images/book1.png',character2),
  Book("金瓶梅詞話", "蘭陵笑笑生", "1610/??/??", 200000, 200000,'assets/books/book2','assets/images/book2.jpg',character3),
  Book("三國演義", "羅貫中", "1522/??/??", 250000, 250000,'assets/books/book3','assets/images/book3.jpg',character4),
  Book("西遊記", "吳承恩", "1592/??/??", 432121, 65331,'assets/books/book4','assets/images/book4.jpg',character5),
  Book("台北人", "白先勇", "1971/??/??", 213312, 55332,'assets/books/book5','assets/images/book5.jpg',character6),
  Book("半生緣", "張愛玲", "2003/??/??", 516628, 103372,'assets/books/book6','assets/images/book6.jpg',character7),
  Book("將軍族", "陳映真", "1964/??/??", 109921, 14252,'assets/books/book7','assets/images/book7.jpg',character8),
  Book("紅樓夢", "程偉元", "1784/??/??", 755689, 123321,'assets/books/book8','assets/images/book8.jpg',character9),
  Book("三體", "劉慈欣", "2008/05/??", 566789, 213424,'assets/books/book9','assets/images/book9.jpg',character10),
];
