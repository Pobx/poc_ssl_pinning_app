import 'dart:convert';
import 'dart:io';

import 'package:basic_utils/basic_utils.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProductApiService {
  final Dio dio;

  ProductApiService({required this.dio});

  Future<void> fetchProduct() async {
    var response = await dio.get("/products/1");

    print(response.data);
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // home: const MyHomePage(title: 'Flutter Demo Home Page'),
      home: Home(),
    );
  }
}

class Home extends StatelessWidget {
  const Home({super.key});

  // final baseUrl = "https://dummyjson.com";
  // final baseOptions = BaseOptions(baseUrl: "https://dummyjson.com");
  // final productApiService = ProductApiService(
  //     dio: Dio(BaseOptions(baseUrl: "https://dummyjson.com")));

  Future<String> _readPemCert(String path) async {
    final sslCert = await rootBundle.load(path);
    final data = sslCert.buffer.asUint8List();
    final pemString = utf8.decode(data);
    final pemArray = pemString.split("-----END CERTIFICATE-----");
    final cert = [pemArray[0], "-----END CERTIFICATE-----"].join("");
    return cert;
  }

  Future<void> _getProduct() async {
    final dio = Dio(BaseOptions(baseUrl: "https://bitkub.com"));

    // const fingerprint =
    //     '96:31:28:EE:B6:E4:83:EC:96:07:72:B6:7F:98:C0:BF:15:84:93:A1:BF:63:5D:81:69:39:48:26:D2:71:01:90';

    // read from pem file ===> 963128EEB6E483EC960772B67F98C0BF158493A1BF635D8169394826D2710190

    // const fingerprint = "bf9f6f045a28b7ea71a4e2180bb481e0166e18c239507fb5a71396b30d832cb5";

    final x509Cert1 = await _readPemCert('assets/cert/public.pem');
    X509CertificateData data = X509Utils.x509CertificateFromPem(x509Cert1);

    print(x509Cert1);

    print(data);
    var fingerprint = data.sha256Thumbprint ?? "";

    print(fingerprint);
    // Don't trust any certificate just because their root cert is trusted
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient(
          context: SecurityContext(withTrustedRoots: false),
        );
        // You can test the intermediate / root cert here. We just ignore it.
        client.badCertificateCallback = (cert, host, port) => true;
        return client;
      },
      validateCertificate: (cert, host, port) {
        // Check that the cert fingerprint matches the one we expect
        // We definitely require _some_ certificate
        if (cert == null) {
          return false;
        }
        // Validate it any way you want. Here we only check that
        // the fingerprint matches the OpenSSL SHA256.
        print(cert);
        final f = sha256.convert(cert.der).toString();
        print(f);
        print(cert.pem);

        X509CertificateData data1 = X509Utils.x509CertificateFromPem(cert.pem);

        print("data ======> ${fingerprint}");
        print("data1 ======> ${data1.sha256Thumbprint ?? ""}");

        var aaa = utf8.encode(fingerprint);
        var bbb = sha256.convert(aaa).toString();
        print(bbb);
        print(data1);

        // return fingerprint == f;
        print("Validate is ${fingerprint == f}");
        return true;
      },
    );

    // var response = await dio.get("/products/1");
    var response = await dio.get("/");
    print(response.data);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(),
        const SizedBox(),
        ElevatedButton(onPressed: _getProduct, child: const Text("Get Product"))
      ],
    );
  }
}

// class MyHomePage extends StatefulWidget {
//   const MyHomePage({super.key, required this.title});

//   final String title;

//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {
//   void _getProduct() async {}

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Theme.of(context).colorScheme.inversePrimary,
//         title: Text(widget.title),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             ElevatedButton(
//                 onPressed: _getProduct, child: const Text("Get prodcut"))
//           ],
//         ),
//       ),
//     );
//   }
// }
