import 'package:alessio_test_task/products/product.dart';
import 'package:alessio_test_task/products/products_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockProductsRepository extends Mock implements ProductsRepository {}

Product product(int id) => Product(
  id: id,
  title: 'Product $id',
  description: 'Description',
  category: 'beauty',
  brand: null,
  price: 10,
  discountPercentage: 0,
  rating: 4,
  stock: 50,
  availabilityStatus: 'In Stock',
  shippingInformation: 'Ships in 3-5 business days',
  returnPolicy: '30 days return policy',
  thumbnail: 'https://example.com/$id.png',
  images: const [],
);
