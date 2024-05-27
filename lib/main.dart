import 'dart:convert';
import 'dart:io';
import 'package:basic_utils/basic_utils.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
      home: const Home(),
    );
  }
}

class Home extends StatelessWidget {
  const Home({super.key});

  Future<String> _readPemCert(String path) async {
    final sslCert = await rootBundle.load(path);
    final data = sslCert.buffer.asUint8List();
    final pemString = utf8.decode(data);
    final pemArray = pemString.split("-----END CERTIFICATE-----");
    final cert = [pemArray[0], "-----END CERTIFICATE-----"].join("");
    return cert;
  }

  Future<void> _getProduct() async {
    final dio = Dio(BaseOptions(baseUrl: "https://dummyjson.com"));
    final x509Cert1 = await _readPemCert('assets/cert/certificate.pem');

    X509CertificateData data = X509Utils.x509CertificateFromPem(x509Cert1);

    print(data);
    var fingerprintClient = data.sha256Thumbprint ?? "";

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
        if (cert == null) {
          return false;
        }

        X509CertificateData data1 = X509Utils.x509CertificateFromPem(cert.pem);
        var fingerprintServer = data1.sha256Thumbprint ?? "";

        print("fingerprintClient ======> $fingerprintClient");
        print("fingerprintServer ======> $fingerprintServer");

        const fingerprintServerFake = "1234";

        print("Validate is ${fingerprintClient == fingerprintServer}");

        return fingerprintClient == fingerprintServer;
      },
    );

    var response = await dio.get("/products/1");
    print(response.data);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
              onPressed: _getProduct, child: const Text("Get Product"))
        ],
      ),
    );
  }
}
