import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gym/core/widgets/custom_text_field.dart';
import 'providers/auth_provider.dart';

class RegisterOwnerScreen extends ConsumerStatefulWidget {
  const RegisterOwnerScreen({super.key});

  @override
  ConsumerState<RegisterOwnerScreen> createState() => _RegisterOwnerScreenState();
}

class _RegisterOwnerScreenState extends ConsumerState<RegisterOwnerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _gymNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _register() async {
    if (_formKey.currentState!.validate()) {
      try {
        await ref.read(authControllerProvider.notifier).registerGymOwner(
          ownerName: _nameController.text.trim(),
          gymName: _gymNameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration Failed: \$e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _gymNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Gym'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Create your Gym account',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                CustomTextField(
                  controller: _nameController,
                  labelText: 'Your Name',
                  hintText: 'Enter your full name',
                  prefixIcon: Icons.person,
                  validator: (val) => val != null && val.isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _gymNameController,
                  labelText: 'Gym Name',
                  hintText: 'Enter your Gym name',
                  prefixIcon: Icons.fitness_center,
                  validator: (val) => val != null && val.isEmpty ? 'Gym Name is required' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _emailController,
                  labelText: 'Email',
                  hintText: 'Enter your email',
                  prefixIcon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) => val != null && val.isEmpty ? 'Email is required' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _passwordController,
                  labelText: 'Password',
                  hintText: 'Enter a strong password',
                  prefixIcon: Icons.lock,
                  isPassword: true,
                  validator: (val) => val != null && val.length < 6 ? 'Password must be 6+ chars' : null,
                ),
                const SizedBox(height: 32),
                if (authState.isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  ElevatedButton(
                    onPressed: _register,
                    child: const Text('Register Gym'),
                  ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('Already have an account? Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
