import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'screens/sites/sites_page.dart';
import 'theme/app_theme.dart';
import 'theme/components.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const AidGridApp());
}

Future<String?> getUserRole() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    debugPrint('ROLE CHECK: No authenticated user');
    return null;
  }

  debugPrint('ROLE CHECK: Auth UID = ${user.uid}');
  debugPrint('ROLE CHECK: Auth email = ${user.email}');

  final userDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();

  debugPrint('ROLE CHECK: Document exists = ${userDoc.exists}');
  debugPrint('ROLE CHECK: Document data = ${userDoc.data()}');

  if (!userDoc.exists) {
    return null;
  }

  final role = userDoc.data()?['role'] as String?;

  debugPrint('ROLE CHECK: Role = $role');

  return role;
}

class AidGridApp extends StatelessWidget {
  const AidGridApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AidGrid',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ),
            );
          }
          if (snapshot.hasData) {
            return FutureBuilder<String?>(
              future: getUserRole(),
              builder: (context, roleSnapshot) {
                if (roleSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  );
                }

                if (roleSnapshot.hasError) {
                  return const Scaffold(
                    body: Center(child: Text('Unable to load user profile.')),
                  );
                }

                final role = roleSnapshot.data?.trim();

                debugPrint('ROUTING: roleSnapshot data = [$role]');
                debugPrint('ROUTING: role length = ${role?.length}');

                if (role == 'ADMIN') {
                  debugPrint('ROUTING: RETURNING ADMIN DASHBOARD');
                  return const AdminDashboardPage();
                }

                debugPrint('ROUTING: RETURNING VOLUNTEER DASHBOARD');
                return const DashboardPage();
              },
            );
          }
          return const LoginPage();
        },
      ),
    );
  }
}

// ---------------------------------------------------------
// Login Page
// ---------------------------------------------------------

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;
  String? errorMessage;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    setState(() {
      errorMessage = null;
      isLoading = true;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        if (e.code == 'invalid-credential' ||
            e.code == 'user-not-found' ||
            e.code == 'wrong-password') {
          errorMessage = 'Email or password is incorrect.';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'Please enter a valid email address.';
        } else {
          errorMessage =
              'Login failed. Please check your connection and try again.';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'An unexpected error occurred. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedContent(
              maxWidth: 420,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const BrandHeader(
                    title: 'AidGrid',
                    subtitle: 'Volunteer & relief distribution network',
                  ),
                  const SizedBox(height: 28),

                  SoberCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'VOLUNTEER SIGN IN',
                          style: AppTypography.labelSmall,
                        ),
                        const SizedBox(height: 18),

                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Email address',
                            hintText: 'name@organization.org',
                            prefixIcon: Icon(
                              Icons.mail_outline_rounded,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        TextField(
                          controller: passwordController,
                          obscureText: obscurePassword,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => login(),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(
                              Icons.lock_outline_rounded,
                              size: 20,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 18,
                                color: AppColors.textMuted,
                              ),
                              onPressed: () {
                                setState(() {
                                  obscurePassword = !obscurePassword;
                                });
                              },
                            ),
                          ),
                        ),

                        if (errorMessage != null) ...[
                          const SizedBox(height: 16),
                          NoticeBanner(message: errorMessage!),
                        ],

                        const SizedBox(height: 22),

                        ElevatedButton(
                          onPressed: isLoading ? null : login,
                          child: isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Sign In'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account?",
                        style: AppTypography.bodyMedium,
                      ),
                      const SizedBox(width: 4),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterPage(),
                            ),
                          );
                        },
                        child: const Text('Register as volunteer'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// Register Page
// ---------------------------------------------------------

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;
  String? errorMessage;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> register() async {
    setState(() {
      errorMessage = null;
      isLoading = true;
    });

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set({
            'name': nameController.text.trim(),
            'email': emailController.text.trim(),
            'role': 'VOLUNTEER',
          });

      if (nameController.text.trim().isNotEmpty) {
        await credential.user?.updateDisplayName(nameController.text.trim());
      }

      debugPrint('User registered: ${credential.user?.uid}');
      if (mounted) {
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        if (e.code == 'email-already-in-use') {
          errorMessage = 'This email is already registered.';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'Please enter a valid email address.';
        } else if (e.code == 'weak-password') {
          errorMessage = 'Password must be at least 6 characters.';
        } else {
          errorMessage =
              'Registration could not be completed. Please try again.';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'An unexpected error occurred. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedContent(
              maxWidth: 420,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const BrandHeader(
                    title: 'New Volunteer',
                    subtitle:
                        'Register your account to coordinate distribution',
                  ),
                  const SizedBox(height: 24),

                  SoberCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'VOLUNTEER DETAILS',
                          style: AppTypography.labelSmall,
                        ),
                        const SizedBox(height: 18),

                        TextField(
                          controller: nameController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Full name',
                            hintText: 'Jane Doe',
                            prefixIcon: Icon(
                              Icons.person_outline_rounded,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Email address',
                            hintText: 'name@organization.org',
                            prefixIcon: Icon(
                              Icons.mail_outline_rounded,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        TextField(
                          controller: passwordController,
                          obscureText: obscurePassword,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => register(),
                          decoration: InputDecoration(
                            labelText: 'Create password',
                            prefixIcon: const Icon(
                              Icons.lock_outline_rounded,
                              size: 20,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 18,
                                color: AppColors.textMuted,
                              ),
                              onPressed: () {
                                setState(() {
                                  obscurePassword = !obscurePassword;
                                });
                              },
                            ),
                          ),
                        ),

                        if (errorMessage != null) ...[
                          const SizedBox(height: 16),
                          NoticeBanner(message: errorMessage!),
                        ],

                        const SizedBox(height: 22),

                        ElevatedButton(
                          onPressed: isLoading ? null : register,
                          child: isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Create Account'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account?',
                        style: AppTypography.bodyMedium,
                      ),
                      const SizedBox(width: 4),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Log in'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('ADMIN DASHBOARD: BUILDING');

    return Scaffold(
      appBar: AppBar(
        title: const Text('AidGrid Admin'),
        actions: [
          IconButton(
            tooltip: 'Sign Out',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedContent(
            maxWidth: 760,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ADMIN DASHBOARD', style: AppTypography.labelSmall),

                const SizedBox(height: 8),

                Text('Welcome back, Admin', style: AppTypography.titleLarge),

                const SizedBox(height: 24),

                SoberCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.inventory_2_outlined, size: 28),

                      const SizedBox(height: 12),

                      Text(
                        'Inventory Management',
                        style: AppTypography.titleMedium,
                      ),

                      const SizedBox(height: 6),

                      Text(
                        'View and manage food supplies across AidGrid.',
                        style: AppTypography.bodyMedium,
                      ),

                      const SizedBox(height: 16),

                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const InventoryPage(),
                            ),
                          );
                        },
                        child: const Text('Open Inventory'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                SoberCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_city_outlined, size: 28),

                      const SizedBox(height: 12),

                      Text(
                        'Sites & Communities',
                        style: AppTypography.titleMedium,
                      ),

                      const SizedBox(height: 6),

                      Text(
                        'View and manage distribution centers and community hubs.',
                        style: AppTypography.bodyMedium,
                      ),

                      const SizedBox(height: 16),

                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SitesPage(),
                            ),
                          );
                        },
                        child: const Text('Open Sites'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class InventoryPage extends StatelessWidget {
  const InventoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Inventory"),
        actions: [
          IconButton(
            tooltip: 'Add Inventory',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddInventoryPage(),
                ),
              );
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('Inventory').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Unable to load inventory.'));
          }

          final items = snapshot.data?.docs ?? [];

          if (items.isEmpty) {
            return const Center(child: Text('No inventory items found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index].data() as Map<String, dynamic>;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SoberCard(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.inventory_2_outlined,
                          color: AppColors.primary,
                        ),
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['name'] ?? 'Unnamed item',
                              style: AppTypography.titleMedium,
                            ),

                            const SizedBox(height: 4),

                            Text(
                              '${item['quantity']} ${item['unit']}',
                              style: AppTypography.bodyMedium,
                            ),
                          ],
                        ),
                      ),

                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item['category'] ?? '',
                            style: AppTypography.labelSmall,
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: 'Edit inventory',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditInventoryPage(
                                    documentId: items[index].id,
                                    name: item['name'] ?? '',
                                    category: item['category'] ?? '',
                                    quantity:
                                        item['quantity']?.toString() ?? '',
                                    unit: item['unit'] ?? '',
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            tooltip: 'Delete inventory',
                            onPressed: () async {
                              final shouldDelete = await showDialog<bool>(
                                context: context,
                                builder: (dialogContext) {
                                  return AlertDialog(
                                    title: const Text("Delete inventory Item?"),
                                    content: const Text(
                                      'Are you sure you want to delete this item? '
                                      'This action cannot be undone.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(dialogContext, false);
                                        },
                                        child: const Text("Cancel"),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(dialogContext, true);
                                        },
                                        child: const Text("Delete"),
                                      ),
                                    ],
                                  );
                                },
                              );
                              if (shouldDelete != true) return;

                              try {
                                await FirebaseFirestore.instance
                                    .collection('Inventory')
                                    .doc(items[index].id)
                                    .delete();
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Inventory item deleted successfully",
                                    ),
                                  ),
                                );
                              } catch (e) {
                                debugPrint('Error deleting Inventory $e');
                                if (!context.mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Failed to delete inventory item',
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class AddInventoryPage extends StatefulWidget {
  const AddInventoryPage({super.key});

  @override
  State<AddInventoryPage> createState() => _AddInventoryPageState();
}

class _AddInventoryPageState extends State<AddInventoryPage> {
  final nameController = TextEditingController();
  final categoryController = TextEditingController();
  final quantityController = TextEditingController();
  final unitController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    categoryController.dispose();
    quantityController.dispose();
    unitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Inventory')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Item name',
                  hintText: 'e.g. Rice',
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  hintText: 'e.g. Grains',
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  hintText: 'e.g. 100',
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: unitController,
                decoration: const InputDecoration(
                  labelText: 'Unit',
                  hintText: 'e.g. kg',
                ),
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  final category = categoryController.text.trim();
                  final quantityText = quantityController.text.trim();
                  final unit = unitController.text.trim();

                  if (name.isEmpty ||
                      category.isEmpty ||
                      quantityText.isEmpty ||
                      unit.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please fill in all fields'),
                      ),
                    );
                    return;
                  }

                  final quantity = int.tryParse(quantityText);

                  if (quantity == null || quantity < 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid quantity'),
                      ),
                    );
                    return;
                  }

                  try {
                    await FirebaseFirestore.instance
                        .collection('Inventory')
                        .add({
                          'name': name,
                          'category': category,
                          'quantity': quantity,
                          'unit': unit,
                        });

                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Inventory item added successfully'),
                      ),
                    );

                    Navigator.pop(context);
                  } catch (e) {
                    debugPrint('ERROR ADDING INVENTORY: $e');

                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to add inventory item'),
                      ),
                    );
                  }
                },
                child: const Text('Add Item'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EditInventoryPage extends StatefulWidget {
  final String documentId;
  final String name;
  final String category;
  final String quantity;
  final String unit;

  const EditInventoryPage({
    super.key,
    required this.documentId,
    required this.name,
    required this.category,
    required this.quantity,
    required this.unit,
  });

  @override
  State<EditInventoryPage> createState() => _EditInventoryPageState();
}

class _EditInventoryPageState extends State<EditInventoryPage> {
  late final TextEditingController nameController;
  late final TextEditingController categoryController;
  late final TextEditingController quantityController;
  late final TextEditingController unitController;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(text: widget.name);
    categoryController = TextEditingController(text: widget.category);
    quantityController = TextEditingController(text: widget.quantity);
    unitController = TextEditingController(text: widget.unit);
  }

  @override
  void dispose() {
    nameController.dispose();
    categoryController.dispose();
    quantityController.dispose();
    unitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Inventory')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Item name'),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantity'),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: unitController,
                decoration: const InputDecoration(labelText: 'Unit'),
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  final category = categoryController.text.trim();
                  final quantityText = quantityController.text.trim();
                  final unit = unitController.text.trim();

                  if (name.isEmpty ||
                      category.isEmpty ||
                      quantityText.isEmpty ||
                      unit.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please fill in all fields'),
                      ),
                    );
                    return;
                  }

                  final quantity = int.tryParse(quantityText);

                  if (quantity == null || quantity < 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid quantity'),
                      ),
                    );
                    return;
                  }

                  try {
                    await FirebaseFirestore.instance
                        .collection('Inventory')
                        .doc(widget.documentId)
                        .update({
                          'name': name,
                          'category': category,
                          'quantity': quantity,
                          'unit': unit,
                        });

                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Inventory updated successfully'),
                      ),
                    );

                    Navigator.pop(context);
                  } catch (e) {
                    debugPrint('ERROR UPDATING INVENTORY: $e');

                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to update inventory'),
                      ),
                    );
                  }
                },
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// Dashboard Page
// ---------------------------------------------------------

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userName =
        user?.displayName ??
        (user?.email != null ? user!.email!.split('@')[0] : 'Volunteer');

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: const Text(
                'A',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'AidGrid',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 17,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        actions: [
          const SoberBadge(
            label: 'Shift Active',
            backgroundColor: AppColors.successContainer,
            textColor: AppColors.success,
            icon: Icons.check_circle_outline,
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Sign Out',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
            icon: const Icon(Icons.logout_rounded, size: 20),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedContent(
            maxWidth: 760,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Welcome & Status Banner
                SoberCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back, $userName',
                              style: AppTypography.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Central Hub 04 · Active distribution cycle',
                              style: AppTypography.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.eco_outlined,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Metrics / Overview Cards
                Text('CURRENT STATUS', style: AppTypography.labelSmall),
                const SizedBox(height: 12),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 540;
                    if (isNarrow) {
                      return const Column(
                        children: [
                          StatMetricTile(
                            label: 'Inventory',
                            value: '420 kg',
                            caption: 'Rice, wheat & dry rations',
                            icon: Icons.inventory_2_outlined,
                          ),
                          SizedBox(height: 12),
                          StatMetricTile(
                            label: 'Assignments',
                            value: '3 Active',
                            caption: '2 in transit, 1 preparing',
                            icon: Icons.local_shipping_outlined,
                          ),
                        ],
                      );
                    }

                    return const Row(
                      children: [
                        Expanded(
                          child: StatMetricTile(
                            label: 'Inventory',
                            value: '420 kg',
                            caption: 'Rice, wheat & dry rations',
                            icon: Icons.inventory_2_outlined,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: StatMetricTile(
                            label: 'Assignments',
                            value: '3 Active',
                            caption: '2 in transit, 1 preparing',
                            icon: Icons.local_shipping_outlined,
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const InventoryPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.inventory_2_outlined),
                    label: const Text('View Inventory'),
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SitesPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.location_city_outlined),
                    label: const Text('View Sites & Communities'),
                  ),
                ),

                const SizedBox(height: 28),

                // Recent Activity Feed
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('RECENT DISPATCHES', style: AppTypography.labelSmall),
                    const SoberBadge(
                      label: 'Live sync',
                      backgroundColor: AppColors.secondaryContainer,
                      textColor: AppColors.textSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                SoberCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: const [
                      _ActivityTile(
                        icon: Icons.grain_outlined,
                        title: 'Rice distributed',
                        location: 'Shelter Point 02 · Zone B',
                        time: '18m ago',
                        quantity: '20 kg',
                      ),
                      Divider(height: 1),
                      _ActivityTile(
                        icon: Icons.water_drop_outlined,
                        title: 'Drinking water crates dispatched',
                        location: 'Community Center 07',
                        time: '1h ago',
                        quantity: '40 L',
                      ),
                      Divider(height: 1),
                      _ActivityTile(
                        icon: Icons.medication_outlined,
                        title: 'First-aid emergency kits',
                        location: 'Mobile Clinic Unit 01',
                        time: '3h ago',
                        quantity: '12 kits',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String location;
  final String time;
  final String quantity;

  const _ActivityTile({
    required this.icon,
    required this.title,
    required this.location,
    required this.time,
    required this.quantity,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.divider),
            ),
            child: Icon(icon, size: 18, color: AppColors.secondary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$location · $time',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SoberBadge(
            label: quantity,
            backgroundColor: AppColors.canvas,
            textColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
