'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"flutter_bootstrap.js": "132a92e7611537067788a19441ab8681",
"version.json": "029824852006f670561cf1eed88a6b55",
"index.html": "2602e0aced09d47a16b0373eafb93ba9",
"/": "2602e0aced09d47a16b0373eafb93ba9",
"main.dart.js": "118bc952b924647fa6e636d6236f562b",
"sqlite3.wasm": "fa7637a49a0e434f2a98f9981856d118",
"flutter.js": "83d881c1dbb6d6bcd6b42e274605b69c",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"sqflite_sw.js": "a33648db91d964fd2b07ab8e663ee34f",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"manifest.json": "00d8de02bdc37ab089e2907c2290e251",
".git/config": "a365682c5c0d5e6c7b1265eaa02d70bc",
".git/objects/92/316814c11d8a6f65f140b76f227679598bf6a3": "26cb0be3de69f9730d4514484d01d5a6",
".git/objects/3e/2e097b6da6e9437b8e46430961f7275341305a": "e9f1dc08f58e086f6b770306ed4e4207",
".git/objects/57/2c7e6d5dbe888c16ad0bb0378eee3c92ae6f6d": "1e37c54514cf020e6fc3ad9134f92686",
".git/objects/9b/d3accc7e6a1485f4b1ddfbeeaae04e67e121d8": "784f8e1966649133f308f05f2d98214f",
".git/objects/9e/3dbecf639967d7aaf55894165ded9069eb4665": "4148409e8d6333361c03375b344df052",
".git/objects/69/74b1a0ff5647068f199b21c5e25124dda4e51e": "910ffae061a5f7227cd41442aaf84439",
".git/objects/3d/741f5ed32eae4aa94cd2fd4f39fc867893552e": "630d8be01cf1a39a0027250bb0bae4b2",
".git/objects/58/31840272dc1c691085a1cda9eff0467b035365": "adfbc6c173c4e9b037c82eb43ea9b9d0",
".git/objects/58/546faffbc74df14edbe07c244a0f9afdb6cc66": "ff4db1241af5b247468e4cbcfcfc1ed8",
".git/objects/94/fce6fe0fd2086a53f003b27d85f4110267b752": "105f59f103929d6d1fd20bfaf12d7b14",
".git/objects/94/dae3d7d0b6672968ae989debbdfdae33a852b1": "0d5eaac817b46a17989cdd2138188a33",
".git/objects/5a/27f8573fab15de50ddd795cf1e59b59c55c7f6": "fdb80eebf7b6fbd8b2610ef8701fd89d",
".git/objects/02/1dd1d491cd70ebb8b66d1af4c9d8bf2a221511": "d599204d95de4cf3e729fbac57461c20",
".git/objects/d9/7e1fadb6ceff6b6d1627479399b226e376de0d": "b9cf668a42be4fb742c1755f502fbf32",
".git/objects/be/71fe4b2c81a6306153abdff0da1745c73e328f": "ef6671b85ff87f39704bf64d8a30d523",
".git/objects/df/13f187372445c12168bbee25e09885d860685b": "eb1753c32b7ccb6ada8f11390491736b",
".git/objects/da/14f5a021f93dff0544386066fb7f7c8b7dbee5": "ae682d026a369602b452b42b2c5ecaf5",
".git/objects/d6/9c56691fbdb0b7efa65097c7cc1edac12a6d3e": "868ce37a3a78b0606713733248a2f579",
".git/objects/bc/4a0d5774742794e6bae527bb109ebce6473092": "6b21e82f71d3debb913bb6360f036279",
".git/objects/bc/f2d36271fc2bf275c68b33134bea4ece1f47cc": "a687a1837245892b41083399d768ebc6",
".git/objects/d8/36fc7741a6f18f6b5c976b2b43d1fda1b546be": "54bfe7a6fd4b898a46df7c5ccd851bf5",
".git/objects/eb/9b4d76e525556d5d89141648c724331630325d": "37c0954235cbe27c4d93e74fe9a578ef",
".git/objects/c7/b171b03abdae9922b2d5ee75b08c87a8750c79": "4a872dd5518433509f74b2693c0c6a63",
".git/objects/fc/670d19e6e092a6aaa54a55eee38b010849b592": "db30ba7b07ab1aaa8d98491333de54a7",
".git/objects/fd/e7b56e4a101e25dc60b139fdd5d8c4da6f070c": "9845988e080b93967eabe3571f01dc05",
".git/objects/fd/41e21e5e8006862f594d2d1d48c3f0fe8f3bcb": "e240ae97b88ff84443bfeb514db16121",
".git/objects/f2/04823a42f2d890f945f70d88b8e2d921c6ae26": "6b47f314ffc35cf6a1ced3208ecc857d",
".git/objects/e3/c0e53f223dd0906bc634b45d8b13f119aa9dd2": "9a6aa7843474b161a3b70fb19a945e40",
".git/objects/18/d48c0a7fca0bc903404f1c2721cda9c3df13f7": "5320eff7398b5eb38a8d3361c3cdad88",
".git/objects/1f/16f96b4950e9825898f332e4d3fe761eabeb53": "dc49026b08ad4dd66cbcb6f71873b8ae",
".git/objects/87/026e6d11ebae772f8928e0574f718b7a99ab03": "f9f8649965fed10c67575a52eb48d76d",
".git/objects/8a/c1a09e3944cf56e870d668e46aa33f5ab9deab": "2dc48a59196c2a47d6633a97ea00a138",
".git/objects/8a/aa46ac1ae21512746f852a42ba87e4165dfdd1": "1d8820d345e38b30de033aa4b5a23e7b",
".git/objects/7e/c0e2e37a49d9534088c29bd768ebc9eab7cd60": "04a61bd95feee8a53dc6f681d3dde137",
".git/objects/19/47055c538835700972b1b86bf6f421bc7e9f8d": "7dc1c5f9210f5ce39a10e4741e3443a0",
".git/objects/21/5b45df910847887f4d7ff7e8e99e9dcaca7f25": "85f3d9ee42c551d4a246a148559ef30d",
".git/objects/21/4215a03b2343798e31d9cbcc9d8029380a11ad": "b0486f433d29368a047e2605d1a4d154",
".git/objects/2f/04653346fd01cf5870091728263aa29ab74e30": "6eee246fb047c369696487fac2522926",
".git/objects/2f/5cc8a5666866cabe32f29ca881cb0d62bf49bd": "efc2c4346f61190dfbaa3b3cf7556de8",
".git/objects/88/2f4f56c84021f1a483daa112058f870bd1c183": "3527ff9e502653bab48d7c11078f9817",
".git/objects/88/cfd48dff1169879ba46840804b412fe02fefd6": "e42aaae6a4cbfbc9f6326f1fa9e3380c",
".git/objects/07/29d99ce1b75a66f26254a5121df075cb415bf1": "3ea3a23b31da6be9fd3b6a72c0087258",
".git/objects/9a/54a12e07518d774d1aec7f8994c2ac75cc147f": "62e5b19dc0e38064163a0f5de7638115",
".git/objects/36/eab7e97fdf5c02635e7f4968a07bbf8d1d3f0d": "fac5976b63c8e455bab5021339d0ab8d",
".git/objects/31/edfe0161ac7c9117968bc771793148e630f501": "fcc5d3924928b9eb3261fa4aeafc0a80",
".git/objects/31/305b355ebfb2c4cb9734ef92ee79b5dd5ac95c": "2754c2accad443a74b709d215b82cd45",
".git/objects/5e/a13c953ec566013192e5981b861defe0b32589": "6600601e77232ffdf5a60d3f6e2df834",
".git/objects/39/73553da1e9d498e2fa681836f097618851b5f2": "fb55ad20f331791cbef725ab2a064269",
".git/objects/39/29a846e5ab85a8b94d73f287e9b07792b31a8a": "a6e3e919c4d86d90d4d3d0f569b3a8ca",
".git/objects/63/f600daaa2205b475fb49f1ee6774e215387fe2": "07ec8786d0ff2324eccff4094033a8d9",
".git/objects/64/a4b22c78c4d46667d23691ea5c9b7754c29436": "c5982e6e972a417388770ab5a9218529",
".git/objects/d3/a50a3db2546f068fe2f71d6ebfd63bce290178": "9e22736e074f0357ea59f7a2706235aa",
".git/objects/d4/3532a2348cc9c26053ddb5802f0e5d4b8abc05": "3dad9b209346b1723bb2cc68e7e42a44",
".git/objects/ba/c4f990ab4a53ec81306365b3d810bb0a7af3a3": "1c6218a992e3ea082576eb1bc249aedc",
".git/objects/a0/f8b110aca8ae3219679ff2f8aaf441f3102b78": "df770866068d9f8bd1d9f63008e36399",
".git/objects/dc/11fdb45a686de35a7f8c24f3ac5f134761b8a9": "761c08dfe3c67fe7f31a98f6e2be3c9c",
".git/objects/b7/49bfef07473333cf1dd31e9eed89862a5d52aa": "36b4020dca303986cad10924774fb5dc",
".git/objects/a8/67ac60c2749700ccb1b43d1c7cc7983af141ed": "6454dc2e5b82fc1f686002ffd73c8f22",
".git/objects/a8/429ac636f3feb9e20fefdee19fc4a67a357bb3": "8ba3de4365c7f81bb5d9a4cd72778bf2",
".git/objects/a8/6f703084d17020859a78f48b1175cc0d672a94": "efb2d3f99c30fff1f13ae08e6c33b7a5",
".git/objects/b9/2a0d854da9a8f73216c4a0ef07a0f0a44e4373": "f62d1eb7f51165e2a6d2ef1921f976f3",
".git/objects/b9/51427365e1f6d193c09600f667aab4115a0084": "5bc89d3d643a91159605cb876b254058",
".git/objects/b9/6a5236065a6c0fb7193cb2bb2f538b2d7b4788": "4227e5e94459652d40710ef438055fe5",
".git/objects/c4/85af4c39d95e1027926430f8ccd63edf5eb288": "dab74f8bce764fe851f3fb46c298bc36",
".git/objects/ea/8f9013304d27e7a7132d307e7409b23b74cb1f": "0cce5d7a6dd8c0e4a122026f8a416e36",
".git/objects/ea/19414de3847b9be8fc0bb8668e474c491fc30d": "732c36add4c4a8af8fbc220e3fc2ebfc",
".git/objects/e1/7ccb1c34e1455bf615294dc0509afa05983386": "74294090e31c4b5f6ab96a70dd123c91",
".git/objects/cc/3b586c367ecf285aae12f7963e097aea0e7466": "1c34bbac2eaba0947baecd81f7df23a5",
".git/objects/f9/9fca7f36d0d3dd4aa91b25cb744d9160a4209e": "96d31cee5857dde52ae3fe954b553d1b",
".git/objects/f7/3bdbebf7175c545c3342869b93c33f65d84205": "450bcff3390fef1b3433126123f40135",
".git/objects/ff/9819dd38bd7f611245b05a5a2e36c9e772ad7a": "bfe1794b53e16238ec012dcf11770568",
".git/objects/c2/de2acec1324290949b2241c8c14a01b1913091": "5b0c52a514133f5d5dd0063460f063a0",
".git/objects/f1/c7426e90c7ebd57698b1ffcca02a9d2471f4bc": "41bffe5164a1913961306a72963d2f02",
".git/objects/f8/7ce942ce56be62c9352588ffbe4e67734e19f7": "1da254385c4661221581f5909cc5e36a",
".git/objects/f8/1aea4636baf87799cd4096486a97b25942dd49": "071b6a42187fd0ae3865faf7decc7cca",
".git/objects/ce/d9f1d47feec51050b91339ec0d6e3e2b834002": "e55619e9bf242a1e4d999e6b9e64b08b",
".git/objects/46/4ab5882a2234c39b1a4dbad5feba0954478155": "2e52a767dc04391de7b4d0beb32e7fc4",
".git/objects/2d/35149ab43997fa500184b66a5cb1bcde20f66b": "72096ad6edb0606d0e714ac57b1e6bc6",
".git/objects/1b/4662d8823313431fd256bd1f056f01709d8f37": "04be05861e2bd6ac75d74f786234ee1b",
".git/objects/48/37533a8ffb636e111644446b8b5254d152a146": "54ab11d80a5332cf91fd2999264849ea",
".git/objects/70/a234a3df0f8c93b4c4742536b997bf04980585": "d95736cd43d2676a49e58b0ee61c1fb9",
".git/objects/4a/4d2f422ed47a41d236a7fe17bb6935a82cd032": "b523bd2acd5b5dfb9ecd11997d58c194",
".git/objects/23/18580ba62e859fc1d16aa1bf3814f1cc2b1683": "faf187288d4ceb8619f4083cf9472a32",
".git/objects/71/c0c65ade7ea04f3e712154f914e34d4e362a9a": "b51a243abec0ca6dd37d14cc4aff7d7f",
".git/objects/82/09f77036655d8ecf486cdd18a05782e2e620e2": "9b6cad28330df1623ec7051c0aaa1b13",
".git/objects/40/261089b9488d0f86cfa7dd5a55325e1b391292": "db5448350fdb132e2d6c1c4b695d5e8f",
".git/objects/8e/ec7b2f333759b5b5db22f90e55b8a1c9210b6e": "c564554ce975434c013c7f11d7fb0392",
".git/objects/25/deaeef42c652570527c9cc1e1b39e14ce53f85": "f60d71ac974952366f2f79a374a8b4d6",
".git/HEAD": "cf7dd3ce51958c5f13fece957cc417fb",
".git/info/exclude": "036208b4a1ab4a235d75c181e685e5a3",
".git/logs/HEAD": "2bcf50587bc1dede45186a831c1dfdf9",
".git/logs/refs/heads/main": "2bcf50587bc1dede45186a831c1dfdf9",
".git/logs/refs/remotes/origin/gh-pages": "970930527a9518d2aabc07bbe03fa0dd",
".git/description": "a0a7c3fff21f2aea3cfa1d0316dd816c",
".git/hooks/commit-msg.sample": "579a3c1e12a1e74a98169175fb913012",
".git/hooks/pre-rebase.sample": "56e45f2bcbc8226d2b4200f7c46371bf",
".git/hooks/pre-commit.sample": "305eadbbcd6f6d2567e033ad12aabbc4",
".git/hooks/applypatch-msg.sample": "ce562e08d8098926a3862fc6e7905199",
".git/hooks/fsmonitor-watchman.sample": "a0b2633a2c8e97501610bd3f73da66fc",
".git/hooks/pre-receive.sample": "2ad18ec82c20af7b5926ed9cea6aeedd",
".git/hooks/prepare-commit-msg.sample": "2b5c047bdb474555e1787db32b2d2fc5",
".git/hooks/post-update.sample": "2b7ea5cee3c49ff53d41e00785eb974c",
".git/hooks/pre-merge-commit.sample": "39cb268e2a85d436b9eb6f47614c3cbc",
".git/hooks/pre-applypatch.sample": "054f9ffb8bfe04a599751cc757226dda",
".git/hooks/pre-push.sample": "2c642152299a94e05ea26eae11993b13",
".git/hooks/update.sample": "647ae13c682f7827c22f5fc08a03674e",
".git/hooks/push-to-checkout.sample": "c7ab00c7784efeadad3ae9b228d4b4db",
".git/refs/heads/main": "dbac002221ebb093ee4d01aae30cd864",
".git/refs/remotes/origin/gh-pages": "dbac002221ebb093ee4d01aae30cd864",
".git/index": "0d5999cbd46e2874a6a7e8e57e1e51a1",
".git/COMMIT_EDITMSG": "679cdc5f0c6a08269dad713ae63a3582",
"assets/AssetManifest.json": "4271cfa8fa3e78446d80fc9726827c3a",
"assets/NOTICES": "f30200018d10c5dd498d2a3b3681350e",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/AssetManifest.bin.json": "29e09292b7298550043e207c26c50a43",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "825e75415ebd366b740bb49659d7a5c6",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/AssetManifest.bin": "75d93e7c27e90f6ec490b0ae4e136870",
"assets/fonts/MaterialIcons-Regular.otf": "79a3f217068e22f9541a038b702f63ac",
"assets/assets/images/up_cover.png": "03f82be8cc19ad32d35b7d98033d9bee",
"assets/assets/images/friendsgarden.jpg": "1d11512bf0608180e1cac8275e8a99ad",
"assets/assets/images/desk.jpg": "f3b57197c9729e94c5a90daede41ee75",
"assets/assets/images/libary-.jpg": "14d2627479090066e3d07abc8bc9e0df",
"assets/assets/images/cafe.jpg": "a37b3de7960071c62f985b560df101e1",
"assets/assets/images/forest.jpg": "c6a4663c0ac75bb902e9eb9a60484275",
"assets/assets/images/friends.jpg": "44edd93b59037abe3824048f64b96635",
"assets/assets/images/sea.jpg": "aa8864e270390ee5143c46790c49ebf7",
"assets/assets/images/logo.png": "19f1ede9190bf525991138ae78260970",
"assets/assets/images/mountain.jpg": "de75777c86c69fcce8c925a1dbfeff33",
"assets/assets/images/mountain1.png": "8e201ae3bcc2ae7142d658f457dbd894",
"assets/assets/images/oldtown.jpg": "e4c0be1cd558f13fb60633f1ffc4e324",
"assets/assets/novel_covers/novel_20_drama_romance.jpg": "5ef6847b3fe00bd0a3933928b8262888",
"assets/assets/novel_covers/novel_12_romance_comedy.jpg": "c5919c90db302d06535fd8662822541c",
"assets/assets/novel_covers/novel_2_romance.jpg": "13b8591475a952075895a75bd8ef021c",
"assets/assets/novel_covers/novel_16_action.jpg": "2b2bbef10f4ea092b13196fa84a85381",
"assets/assets/novel_covers/novel_6_action.jpg": "00cfeac7b74987b39a84395c94741b66",
"assets/assets/novel_covers/novel_11_fantasy.jpg": "9e06f53e1b5f977fc621803677b0f97b",
"assets/assets/novel_covers/novel_8_period_romance.jpg": "7743a6b150cfd37d6f9c38fb3a060073",
"assets/assets/novel_covers/novel_19_martial_drama.jpg": "b7b109737fee0b0e0b1ff5f688ef37f4",
"assets/assets/novel_covers/novel_10_drama.jpg": "f910160fd262bfd77abeb6f048308674",
"assets/assets/novel_covers/novel_3_scifi.jpg": "329469010cc7185d4b78d28f286ae65f",
"assets/assets/novel_covers/novel_13_scifi.jpg": "0b000f883bf64e9f0266f7fa29097ad0",
"assets/assets/novel_covers/novel_15_detective_action.jpg": "88abbf5b16dcd66e55babccf5cb79de5",
"assets/assets/novel_covers/novel_7_comedy.jpg": "af145f52ba1d527697c31f80cc7a1b28",
"assets/assets/novel_covers/novel_17_comedy_scifi.jpg": "f146c3245c51e76f37a6eb81a24ed0cc",
"assets/assets/novel_covers/novel_5_detective.jpg": "1aaba762f8a8a486f82d188dc852998e",
"assets/assets/novel_covers/novel_1_fantasy.jpg": "aaba131d8f6b9fd5277d0b232773e9e1",
"assets/assets/novel_covers/novel_14_horror_thriller.jpg": "31e5cc1965c75466b423c8e298318fae",
"assets/assets/novel_covers/novel_4_horror.jpg": "d5ed67395f86b18681b11c2662c64575",
"assets/assets/novel_covers/novel_18_period_drama.jpg": "37f61b3dc9c845f572a5cb909ddc546d",
"assets/assets/novel_covers/novel_9_martial.jpg": "b1ebfc6a0c73b0012e627fb85a4f3819",
"canvaskit/skwasm.js": "ea559890a088fe28b4ddf70e17e60052",
"canvaskit/skwasm.js.symbols": "9fe690d47b904d72c7d020bd303adf16",
"canvaskit/canvaskit.js.symbols": "27361387bc24144b46a745f1afe92b50",
"canvaskit/skwasm.wasm": "1c93738510f202d9ff44d36a4760126b",
"canvaskit/chromium/canvaskit.js.symbols": "f7c5e5502d577306fb6d530b1864ff86",
"canvaskit/chromium/canvaskit.js": "8191e843020c832c9cf8852a4b909d4c",
"canvaskit/chromium/canvaskit.wasm": "c054c2c892172308ca5a0bd1d7a7754b",
"canvaskit/canvaskit.js": "728b2d477d9b8c14593d4f9b82b484f3",
"canvaskit/canvaskit.wasm": "a37f2b0af4995714de856e21e882325c"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
