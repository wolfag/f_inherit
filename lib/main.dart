import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

void main() {
  runApp(
    AppStateWidget(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Store',
        home: MyStorePage(),
      ),
    ),
  );
}

class AppState {
  AppState({
    required this.productList,
    this.itemsInCart = const <String>{},
  });

  final List<String> productList;
  final Set<String> itemsInCart;

  AppState copyWith({
    List<String>? productList,
    Set<String>? itemsInCart,
  }) {
    return AppState(
      productList: productList ?? this.productList,
      itemsInCart: itemsInCart ?? this.itemsInCart,
    );
  }
}

class AppStateScope extends InheritedWidget {
  final AppState data;

  AppStateScope(
    this.data, {
    Key? key,
    required Widget child,
  }) : super(key: key, child: child);

  static AppState of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppStateScope>()!.data;
  }

  @override
  bool updateShouldNotify(AppStateScope oldWidget) {
    return data != oldWidget.data;
  }
}

class AppStateWidget extends StatefulWidget {
  AppStateWidget({Key? key, required this.child}) : super(key: key);

  final Widget child;

  static _AppStateWidgetState of(BuildContext context) {
    return context.findAncestorStateOfType<_AppStateWidgetState>()!;
  }

  @override
  State<AppStateWidget> createState() => _AppStateWidgetState();
}

class _AppStateWidgetState extends State<AppStateWidget> {
  AppState _data = AppState(
    productList: Server.getProductList(),
  );

  void setProductList(List<String> newList) {
    if (newList != _data.productList) {
      setState(() {
        _data = _data.copyWith(
          productList: newList,
        );
      });
    }
  }

  void addToCart(String id) {
    if (!_data.itemsInCart.contains(id)) {
      final Set<String> newList = Set<String>.from(_data.itemsInCart);
      newList.add(id);
      setState(() {
        _data = _data.copyWith(
          itemsInCart: newList,
        );
      });
    }
  }

  void removeFromCard(String id) {
    if (_data.itemsInCart.contains(id)) {
      final Set<String> newList = Set<String>.from(_data.itemsInCart);
      newList.remove(id);
      setState(() {
        _data = _data.copyWith(
          itemsInCart: newList,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppStateScope(
      _data,
      child: widget.child,
    );
  }
}

// store page
class MyStorePage extends StatefulWidget {
  MyStorePage({Key? key}) : super(key: key);

  @override
  State<MyStorePage> createState() => _MyStorePageState();
}

class _MyStorePageState extends State<MyStorePage> {
  bool _inSearch = false;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  void _toggleSearch(BuildContext context) {
    setState(() {
      _inSearch = !_inSearch;
    });

    AppStateWidget.of(context).setProductList(Server.getProductList());
    _controller.clear();
  }

  void _handleSearch(BuildContext context) {
    _focusNode.unfocus();
    final String filter = _controller.text;
    AppStateWidget.of(context)
        .setProductList(Server.getProductList(filter: filter));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            leading: Padding(
              padding: EdgeInsets.all(16),
              child: Image.network('$baseAssetURL/google-logo.png'),
            ),
            title: _inSearch
                ? TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    autofocus: true,
                    onSubmitted: (_) => _handleSearch(context),
                    decoration: InputDecoration(
                      hintText: 'Search google store',
                      prefixIcon: IconButton(
                        icon: Icon(Icons.search),
                        onPressed: () => _handleSearch(context),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => _toggleSearch(context),
                      ),
                    ),
                  )
                : null,
            actions: [
              if (!_inSearch)
                IconButton(
                  onPressed: () => _toggleSearch(context),
                  icon: Icon(
                    Icons.search,
                    color: Colors.black,
                  ),
                ),
              ShoppingCartIcon(),
            ],
            backgroundColor: Colors.white,
            pinned: true,
          ),
          SliverToBoxAdapter(
            child: ProductListWidget(),
          )
        ],
      ),
    );
  }
}

// cart icon
class ShoppingCartIcon extends StatelessWidget {
  ShoppingCartIcon({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Set<String> itemsInCart = AppStateScope.of(context).itemsInCart;
    final bool hasPurchase = itemsInCart.length > 0;
    return Stack(
      alignment: Alignment.center,
      children: [
        Padding(
          padding: EdgeInsets.only(right: hasPurchase ? 17 : 10),
          child: Icon(
            Icons.shopping_cart,
            color: Colors.black,
          ),
        ),
        if (hasPurchase)
          Padding(
            padding: EdgeInsets.only(left: 17),
            child: CircleAvatar(
              radius: 8,
              backgroundColor: Colors.lightBlue,
              foregroundColor: Colors.white,
              child: Text(
                itemsInCart.length.toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// product list
class ProductListWidget extends StatelessWidget {
  ProductListWidget({Key? key}) : super(key: key);

  void _handleAddToCart(BuildContext context, String id) {
    AppStateWidget.of(context).addToCart(id);
  }

  void _handleRemoveFromCart(BuildContext context, String id) {
    AppStateWidget.of(context).removeFromCard(id);
  }

  Widget _buildProductTile(BuildContext context, String id) {
    return ProductTile(
      product: Server.getProductById(id),
      purchased: AppStateScope.of(context).itemsInCart.contains(id),
      onAddToCart: () => _handleAddToCart(context, id),
      onRemoveFromCart: () => _handleRemoveFromCart(context, id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> productList = AppStateScope.of(context).productList;
    return Column(
      children: productList
          .map((String id) => _buildProductTile(context, id))
          .toList(),
    );
  }
}

// product tile

class ProductTile extends StatelessWidget {
  ProductTile({
    Key? key,
    required this.product,
    required this.purchased,
    required this.onAddToCart,
    required this.onRemoveFromCart,
  }) : super(key: key);

  final Product product;
  final bool purchased;
  final VoidCallback onAddToCart;
  final VoidCallback onRemoveFromCart;

  @override
  Widget build(BuildContext context) {
    Color getButtonColor(Set<MaterialState> states) {
      return purchased ? Colors.grey : Colors.black;
    }

    BorderSide getButtonSide(Set<MaterialState> states) {
      return BorderSide(
        color: getButtonColor(states),
      );
    }

    return Container(
      margin: EdgeInsets.symmetric(
        vertical: 15,
        horizontal: 40,
      ),
      color: Color(0xfff8f8f8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.all(20),
            child: Text(product.title),
          ),
          Text.rich(
            product.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20),
            child: ElevatedButton(
              style: ButtonStyle(
                foregroundColor:
                    MaterialStateProperty.resolveWith(getButtonColor),
                side: MaterialStateProperty.resolveWith(getButtonSide),
              ),
              onPressed: () {
                purchased ? onRemoveFromCart() : onAddToCart();
              },
              child: purchased
                  ? const Text('Remove from cart')
                  : const Text('Add to cart'),
            ),
          ),
          Image.network(product.pictureURL)
        ],
      ),
    );
  }
}

// dummy server

const String baseAssetURL =
    'https://dartpad-workshops-io2021.web.app/inherited_widget/assets';

const Map<String, Product> kDummyData = {
  '0': Product(
    id: '0',
    title: 'Explore Pixel phones',
    description: TextSpan(children: <TextSpan>[
      TextSpan(
          text: 'Capture the details.\n',
          style: TextStyle(color: Colors.black)),
      TextSpan(
          text: 'Capture your world.', style: TextStyle(color: Colors.blue)),
    ]),
    pictureURL: '$baseAssetURL/pixels.png',
  ),
  '1': Product(
    id: '1',
    title: 'Nest Audio',
    description: TextSpan(children: <TextSpan>[
      TextSpan(text: 'Amazing sound.\n', style: TextStyle(color: Colors.green)),
      TextSpan(text: 'At your command.', style: TextStyle(color: Colors.black)),
    ]),
    pictureURL: '$baseAssetURL/nest.png',
  ),
  '2': Product(
    id: '2',
    title: 'Nest Audio Entertainment packages',
    description: TextSpan(children: <TextSpan>[
      TextSpan(
          text: 'Built for music.\n', style: TextStyle(color: Colors.orange)),
      TextSpan(text: 'Made for you.', style: TextStyle(color: Colors.black)),
    ]),
    pictureURL: '$baseAssetURL/nest-audio-packages.png',
  ),
  '3': Product(
    id: '3',
    title: 'Nest Home Security packages',
    description: TextSpan(children: <TextSpan>[
      TextSpan(text: 'Your home,\n', style: TextStyle(color: Colors.black)),
      TextSpan(text: 'safe and sound.', style: TextStyle(color: Colors.red)),
    ]),
    pictureURL: '$baseAssetURL/nest-home-packages.png',
  ),
};

class Server {
  static Product getProductById(String id) {
    return kDummyData[id]!;
  }

  static List<String> getProductList({String? filter}) {
    if (filter == null) return kDummyData.keys.toList();
    final List<String> ids = <String>[];
    for (final Product product in kDummyData.values) {
      if (product.title.toLowerCase().contains(filter.toLowerCase())) {
        ids.add(product.id);
      }
    }
    return ids;
  }
}

class Product {
  const Product(
      {required this.id,
      required this.pictureURL,
      required this.title,
      required this.description});

  final String id;
  final String pictureURL;
  final String title;
  final TextSpan description;
}
