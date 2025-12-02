import 'package:bitsxlamarato_frontend_2025/utils/functions/helper_functions.dart';
import 'package:flutter/material.dart';
import 'package:bitsxlamarato_frontend_2025/utils/constants/image_strings.dart';
import 'package:bitsxlamarato_frontend_2025/utils/constants/icon_strings.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    return Scaffold(
        body: SingleChildScrollView(
            child: Padding(
                padding: const EdgeInsets.only(
                  top: 56,
                  left: 24.0,
                  right: 24.0,
                  bottom: 24.0,
                ),
                child: Column(
                  children: [
                    ///Logo and title
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image(
                          height: 200,
                          width: 200,
                          image: AssetImage(
                              dark ? TImages.darkLogo : TImages.lightLogo),
                        ),
                        const Text(
                          "Benvingut a LMLG!",
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8.0),
                      ],
                    ),

                    ///Form
                    Form(
                        child: Column(
                      children: [
                        ///Email
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: "Correu electrònic",
                            hintText: "Introdueix el teu correu electrònic",
                          ),
                        ),
                        const SizedBox(height: 16.0),

                        ///Password
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: "Contrasenya",
                            hintText: "Introdueix la teva contrasenya",
                            suffixIcon: Image.asset(
                              TIcons.eyeClosed,
                              height: 2,
                              width: 2,
                            ),
                          ),
                        ),

                        ///Forgot password
                        Row(
                          children: [
                            ///Forgot password
                            TextButton(
                                onPressed: () {},
                                child: const Text(
                                    "T'has oblidat de la contrasenya?")),
                          ],
                        ),
                        const SizedBox(height: 8.0),

                        ///Login button
                        SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {},
                              child: const Text("Inicia sessió"),
                            )),

                        const SizedBox(height: 16.0),

                        Row(
                          children: [
                            Text(
                              "Nou a LMLG?",
                              style: dark
                                  ? const TextStyle(color: Colors.white)
                                  : const TextStyle(color: Colors.black),
                            ),
                            TextButton(
                                onPressed: () {},
                                child: const Text("Registrar-se")),
                          ],
                        )
                      ],
                    ))
                  ],
                ))));
  }
}
