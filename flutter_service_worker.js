'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"flutter_bootstrap.js": "5e03bc84bad067bd4ee087f688434a8d",
"version.json": "029824852006f670561cf1eed88a6b55",
"index.html": "2602e0aced09d47a16b0373eafb93ba9",
"/": "2602e0aced09d47a16b0373eafb93ba9",
"main.dart.js": "8fe4940383142bd0558630169ab8a2bd",
"sqlite3.wasm": "fa7637a49a0e434f2a98f9981856d118",
"flutter.js": "83d881c1dbb6d6bcd6b42e274605b69c",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"sqflite_sw.js": "a33648db91d964fd2b07ab8e663ee34f",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"manifest.json": "00d8de02bdc37ab089e2907c2290e251",
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
