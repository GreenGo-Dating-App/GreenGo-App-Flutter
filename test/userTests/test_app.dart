import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test app wrapper for user tests
/// This creates standalone test screens that don't depend on the actual app's BLoCs
class TestApp extends StatelessWidget {
  final Widget child;

  const TestApp({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: child,
    );
  }
}

/// Simple login screen for testing
class TestLoginScreen extends StatefulWidget {
  const TestLoginScreen({super.key});

  @override
  State<TestLoginScreen> createState() => _TestLoginScreenState();
}

class _TestLoginScreenState extends State<TestLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);

    await Future.delayed(const Duration(milliseconds: 100));

    if (_emailController.text.trim() == 'testuser@example.com' &&
        _passwordController.text == 'TestPass123!') {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const TestMainScreen()),
        );
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid email or password')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Login',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              TextField(
                key: const Key('email_field'),
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                key: const Key('password_field'),
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    key: const Key('password_visibility_toggle'),
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const TestForgotPasswordScreen(),
                      ),
                    );
                  },
                  child: const Text('Forgot Password?'),
                ),
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    key: const Key('login_button'),
                    onPressed: _handleLogin,
                    child: const Text('Login'),
                  ),
                ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const TestRegisterScreen(),
                    ),
                  );
                },
                child: const Text('Create Account'),
              ),
              const SizedBox(height: 16),
              TextButton(
                key: const Key('language_selector'),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Select Language'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            title: const Text('English'),
                            onTap: () => Navigator.pop(context),
                          ),
                          ListTile(
                            title: const Text('Español'),
                            onTap: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: const Text('Language'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Test registration screen
class TestRegisterScreen extends StatefulWidget {
  const TestRegisterScreen({super.key});

  @override
  State<TestRegisterScreen> createState() => _TestRegisterScreenState();
}

class _TestRegisterScreenState extends State<TestRegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _passwordStrength = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _updatePasswordStrength(String password) {
    setState(() {
      if (password.length < 6) {
        _passwordStrength = 'Weak';
      } else if (password.length < 10) {
        _passwordStrength = 'Medium';
      } else {
        _passwordStrength = 'Strong';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  key: const Key('register_email_field'),
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const Key('register_password_field'),
                  controller: _passwordController,
                  obscureText: true,
                  onChanged: _updatePasswordStrength,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_passwordStrength.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _passwordStrength,
                      style: TextStyle(
                        color: _passwordStrength == 'Strong'
                            ? Colors.green
                            : _passwordStrength == 'Medium'
                                ? Colors.orange
                                : Colors.red,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                TextField(
                  key: const Key('confirm_password_field'),
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    key: const Key('register_button'),
                    onPressed: () {
                      if (!_emailController.text.contains('@')) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a valid email'),
                          ),
                        );
                        return;
                      }
                      if (_passwordController.text !=
                          _confirmPasswordController.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Passwords do not match'),
                          ),
                        );
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Registration Successful'),
                        ),
                      );
                    },
                    child: const Text('Register'),
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

/// Test forgot password screen
class TestForgotPasswordScreen extends StatefulWidget {
  const TestForgotPasswordScreen({super.key});

  @override
  State<TestForgotPasswordScreen> createState() => _TestForgotPasswordScreenState();
}

class _TestForgotPasswordScreenState extends State<TestForgotPasswordScreen> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              key: const Key('reset_email_field'),
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: const Key('reset_button'),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password reset email sent'),
                    ),
                  );
                },
                child: const Text('Send Reset Email'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Test main screen (after login) with bottom navigation
class TestMainScreen extends StatefulWidget {
  const TestMainScreen({super.key});

  @override
  State<TestMainScreen> createState() => _TestMainScreenState();
}

class _TestMainScreenState extends State<TestMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const TestDiscoveryScreen(),
    const TestMatchesScreen(),
    const TestConversationsScreen(),
    const TestProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Discover'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Matches'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

/// Test Discovery Screen with swipe cards
class TestDiscoveryScreen extends StatefulWidget {
  const TestDiscoveryScreen({super.key});

  @override
  State<TestDiscoveryScreen> createState() => _TestDiscoveryScreenState();
}

class _TestDiscoveryScreenState extends State<TestDiscoveryScreen> {
  final List<Map<String, String>> _profiles = [
    {'name': 'Sarah', 'age': '25', 'bio': 'Love hiking and coffee'},
    {'name': 'Emma', 'age': '28', 'bio': 'Photographer and traveler'},
    {'name': 'Lisa', 'age': '24', 'bio': 'Music lover'},
  ];
  int _currentIndex = 0;
  String? _feedback;

  void _swipe(String direction) {
    setState(() {
      if (direction == 'right') {
        _feedback = 'like';
      } else if (direction == 'left') {
        _feedback = 'pass';
      } else if (direction == 'up') {
        _feedback = 'super_like';
      }

      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _feedback = null;
            if (_currentIndex < _profiles.length - 1) {
              _currentIndex++;
            }
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentIndex >= _profiles.length) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Discover'),
          actions: [
            IconButton(
              key: const Key('preferences_button'),
              icon: const Icon(Icons.tune),
              onPressed: () => _showPreferences(context),
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No more profiles'),
              const SizedBox(height: 8),
              const Text('Check back later or adjust your preferences'),
              const SizedBox(height: 16),
              ElevatedButton(
                key: const Key('update_preferences_button'),
                onPressed: () => _showPreferences(context),
                child: const Text('Update Preferences'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
        actions: [
          IconButton(
            key: const Key('preferences_button'),
            icon: const Icon(Icons.tune),
            onPressed: () => _showPreferences(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: GestureDetector(
                  key: const Key('swipe_card_stack'),
                  onHorizontalDragEnd: (details) {
                    if (details.primaryVelocity! > 0) {
                      _swipe('right');
                    } else {
                      _swipe('left');
                    }
                  },
                  onVerticalDragEnd: (details) {
                    if (details.primaryVelocity! < 0) {
                      _swipe('up');
                    }
                  },
                  child: Card(
                    key: const Key('swipe_card'),
                    margin: const EdgeInsets.all(16),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TestProfileDetailScreen(
                              profile: _profiles[_currentIndex],
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_profiles[_currentIndex]['name']}, ${_profiles[_currentIndex]['age']}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(_profiles[_currentIndex]['bio']!),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                key: const Key('swipe_buttons'),
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    FloatingActionButton(
                      key: const Key('pass_button'),
                      heroTag: 'pass',
                      onPressed: () => _swipe('left'),
                      child: const Icon(Icons.close),
                    ),
                    FloatingActionButton(
                      key: const Key('super_like_button'),
                      heroTag: 'super',
                      onPressed: () => _swipe('up'),
                      child: const Icon(Icons.star),
                    ),
                    FloatingActionButton(
                      key: const Key('like_button'),
                      heroTag: 'like',
                      onPressed: () => _swipe('right'),
                      child: const Icon(Icons.favorite),
                    ),
                    FloatingActionButton(
                      key: const Key('rewind_button'),
                      heroTag: 'rewind',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Profile restored')),
                        );
                      },
                      child: const Icon(Icons.replay),
                    ),
                    FloatingActionButton(
                      key: const Key('boost_button'),
                      heroTag: 'boost',
                      onPressed: () {},
                      child: const Icon(Icons.bolt),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_feedback != null)
            Center(
              child: Container(
                key: Key('${_feedback}_feedback'),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _feedback == 'like'
                      ? Colors.green
                      : _feedback == 'super_like'
                          ? Colors.blue
                          : Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _feedback == 'like'
                      ? Icons.favorite
                      : _feedback == 'super_like'
                          ? Icons.star
                          : Icons.close,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showPreferences(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxHeight: 400),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Discovery Preferences',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Age Range'),
              Slider(
                key: const Key('age_range_slider'),
                value: 25,
                min: 18,
                max: 50,
                onChanged: (value) {},
              ),
              const SizedBox(height: 8),
              const Text('Distance'),
              Slider(
                key: const Key('distance_slider'),
                value: 50,
                min: 1,
                max: 100,
                onChanged: (value) {},
              ),
              const SizedBox(height: 8),
              DropdownButton<String>(
                key: const Key('gender_filter'),
                value: 'Women',
                items: ['Women', 'Men', 'Everyone']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) {},
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  key: const Key('save_preferences_button'),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Test Profile Detail Screen
class TestProfileDetailScreen extends StatelessWidget {
  final Map<String, String> profile;

  const TestProfileDetailScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: PageView(
                key: const Key('profile_photo_gallery'),
                children: [
                  Container(
                    color: Colors.grey[300],
                    child: const Center(child: Icon(Icons.person, size: 100)),
                  ),
                  Container(
                    color: Colors.grey[400],
                    child: const Center(child: Icon(Icons.person, size: 100)),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      key: const Key('photo_indicator_1'),
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${profile['name']}, ${profile['age']}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'About',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(profile['bio']!),
                    const SizedBox(height: 16),
                    const Text(
                      'Interests',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        Chip(label: Text('Music')),
                        Chip(label: Text('Travel')),
                        Chip(label: Text('Sports')),
                      ],
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

/// Test Matches Screen
class TestMatchesScreen extends StatelessWidget {
  const TestMatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final matches = [
      {'name': 'Anna', 'time': 'Matched 2 hours ago'},
      {'name': 'Maria', 'time': 'Matched yesterday'},
      {'name': 'Julia', 'time': 'Matched 3 days ago'},
    ];

    if (matches.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Matches')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No matches yet'),
              const Text('Start swiping to find your match!'),
              const SizedBox(height: 16),
              ElevatedButton(
                key: const Key('go_to_discovery_button'),
                onPressed: () {},
                child: const Text('Start Swiping'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Matches')),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(seconds: 1));
        },
        child: ListView.builder(
          key: const Key('matches_list'),
          itemCount: matches.length,
          itemBuilder: (context, index) {
            return ListTile(
              key: Key('match_card_$index'),
              leading: CircleAvatar(
                key: Key('match_photo_$index'),
                child: Text(matches[index]['name']![0]),
              ),
              title: Text(
                matches[index]['name']!,
                key: Key('match_name_$index'),
              ),
              subtitle: Text(matches[index]['time']!),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.person),
                        title: const Text('View Profile'),
                        onTap: () => Navigator.pop(context),
                      ),
                      ListTile(
                        leading: const Icon(Icons.message),
                        title: const Text('Send Message'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TestChatScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
              onLongPress: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Unmatch'),
                    content: const Text('Are you sure you want to unmatch?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Match removed')),
                          );
                        },
                        child: const Text('Unmatch'),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// Test Conversations Screen
class TestConversationsScreen extends StatelessWidget {
  const TestConversationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final conversations = [
      {'name': 'Anna', 'lastMessage': 'Hey! How are you?', 'unread': true},
      {'name': 'Maria', 'lastMessage': 'See you tomorrow!', 'unread': false},
      {'name': 'Julia', 'lastMessage': 'Nice to meet you', 'unread': true},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: ListView.builder(
        key: const Key('conversations_list'),
        itemCount: conversations.length,
        itemBuilder: (context, index) {
          final conv = conversations[index];
          return ListTile(
            key: Key('conversation_item_$index'),
            leading: Stack(
              children: [
                CircleAvatar(child: Text(conv['name']!.toString()[0])),
                if (conv['unread'] == true)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      key: Key('unread_badge_$index'),
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            title: Text(conv['name']!.toString()),
            subtitle: Text(conv['lastMessage']!.toString()),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TestChatScreen()),
              );
            },
            onLongPress: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete this conversation?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Conversation deleted')),
                        );
                      },
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Test Chat Screen
class TestChatScreen extends StatefulWidget {
  const TestChatScreen({super.key});

  @override
  State<TestChatScreen> createState() => _TestChatScreenState();
}

class _TestChatScreenState extends State<TestChatScreen> {
  final _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {'text': 'Hey! How are you?', 'sent': false, 'status': 'delivered'},
    {'text': 'I am great! You?', 'sent': true, 'status': 'delivered'},
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;
    setState(() {
      _messages.add({
        'text': _controller.text.trim(),
        'sent': true,
        'status': 'sending',
      });
      _controller.clear();
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _messages.last['status'] = 'delivered';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          key: const Key('chat_partner_profile'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TestProfileDetailScreen(
                  profile: {'name': 'Anna', 'age': '25', 'bio': 'Love coffee'},
                ),
              ),
            );
          },
          child: Row(
            children: [
              const CircleAvatar(child: Text('A')),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Anna'),
                  Container(
                    key: const Key('online_status'),
                    child: const Text(
                      'Online',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          if (_messages.isEmpty)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Start the conversation!'),
                    Text('Say hello to your match'),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                key: const Key('message_list'),
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + 1,
                itemBuilder: (context, index) {
                  if (index == _messages.length) {
                    return Container(
                      key: const Key('typing_indicator'),
                      height: 0,
                    );
                  }
                  final msg = _messages[index];
                  return Align(
                    alignment: msg['sent']
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      key: Key(msg['sent']
                          ? 'sent_message_bubble'
                          : 'received_message_bubble'),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: msg['sent'] ? Colors.green[100] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(msg['text']),
                          if (msg['sent'])
                            Icon(
                              key: Key('message_status_${msg['status']}'),
                              msg['status'] == 'sending'
                                  ? Icons.access_time
                                  : Icons.done_all,
                              size: 12,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('message_input'),
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  key: const Key('send_button'),
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
          Container(
            key: const Key('older_messages_loaded'),
            height: 0,
          ),
        ],
      ),
    );
  }
}

/// Test Profile Screen
class TestProfileScreen extends StatelessWidget {
  const TestProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            key: const Key('notifications_icon'),
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TestNotificationsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              key: const Key('profile_photo'),
              radius: 50,
              child: const Text('JD', style: TextStyle(fontSize: 32)),
            ),
            const SizedBox(height: 16),
            const Text(
              'John Doe',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildProfileButton(context, 'edit_profile_button', Icons.edit, 'Edit Profile', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TestEditProfileScreen()),
              );
            }),
            _buildProfileButton(context, 'achievements_button', Icons.emoji_events, 'Achievements', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TestAchievementsScreen()),
              );
            }),
            _buildProfileButton(context, 'coin_shop_button', Icons.monetization_on, 'Coin Shop', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TestCoinShopScreen()),
              );
            }),
            _buildProfileButton(context, 'subscription_button', Icons.star, 'Premium', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TestSubscriptionScreen()),
              );
            }),
            _buildProfileButton(context, 'settings_button', Icons.settings, 'Settings', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TestSettingsScreen()),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileButton(BuildContext context, String key, IconData icon, String label, VoidCallback onTap) {
    return Card(
      child: ListTile(
        key: Key(key),
        leading: Icon(icon),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

/// Test Edit Profile Screen
class TestEditProfileScreen extends StatelessWidget {
  const TestEditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            key: const Key('edit_basic_info_card'),
            child: ListTile(
              title: const Text('Basic Info'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TestEditBasicInfoScreen()),
                );
              },
            ),
          ),
          Card(
            key: const Key('edit_photos_card'),
            child: ListTile(
              title: const Text('Photos'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TestEditPhotosScreen()),
                );
              },
            ),
          ),
          Card(
            key: const Key('edit_bio_card'),
            child: ListTile(
              title: const Text('Bio'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TestEditBioScreen()),
                );
              },
            ),
          ),
          Card(
            key: const Key('edit_interests_card'),
            child: ListTile(
              title: const Text('Interests'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ),
          Card(
            key: const Key('edit_location_card'),
            child: ListTile(
              title: const Text('Location'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}

/// Test Edit Basic Info Screen
class TestEditBasicInfoScreen extends StatefulWidget {
  const TestEditBasicInfoScreen({super.key});

  @override
  State<TestEditBasicInfoScreen> createState() => _TestEditBasicInfoScreenState();
}

class _TestEditBasicInfoScreenState extends State<TestEditBasicInfoScreen> {
  final _nameController = TextEditingController(text: 'John Doe');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Basic Info')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              key: const Key('name_field'),
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              key: const Key('height_field'),
              title: const Text('Height'),
              subtitle: const Text('175 cm'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => SimpleDialog(
                    children: [
                      SimpleDialogOption(
                        child: const Text('170 cm'),
                        onPressed: () => Navigator.pop(context),
                      ),
                      SimpleDialogOption(
                        child: const Text('175 cm'),
                        onPressed: () => Navigator.pop(context),
                      ),
                      SimpleDialogOption(
                        child: const Text('180 cm'),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                );
              },
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: const Key('save_button'),
                onPressed: () {
                  if (_nameController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Name cannot be empty')),
                    );
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile updated successfully')),
                  );
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Test Edit Photos Screen
class TestEditPhotosScreen extends StatelessWidget {
  const TestEditPhotosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Photos')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                children: [
                  for (int i = 0; i < 3; i++)
                    GestureDetector(
                      key: Key('photo_preview_$i'),
                      onLongPress: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  title: const Text('Delete'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        content: const Text('Delete this photo?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text('No'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text('Yes'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.person),
                      ),
                    ),
                  GestureDetector(
                    key: const Key('add_photo_button'),
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.photo_library),
                              title: const Text('Choose from Gallery'),
                              onTap: () => Navigator.pop(context),
                            ),
                            ListTile(
                              leading: const Icon(Icons.camera_alt),
                              title: const Text('Take Photo'),
                              onTap: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: const Icon(Icons.add),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: const Key('save_button'),
                onPressed: () => Navigator.pop(context),
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Test Edit Bio Screen
class TestEditBioScreen extends StatefulWidget {
  const TestEditBioScreen({super.key});

  @override
  State<TestEditBioScreen> createState() => _TestEditBioScreenState();
}

class _TestEditBioScreenState extends State<TestEditBioScreen> {
  final _bioController = TextEditingController(text: 'Love hiking and coffee');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bio'),
        leading: BackButton(
          onPressed: () {
            if (_bioController.text != 'Love hiking and coffee') {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Discard changes?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      child: const Text('Discard'),
                    ),
                  ],
                ),
              );
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              key: const Key('bio_field'),
              controller: _bioController,
              maxLines: 5,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Bio',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() {}),
            ),
            Text('${_bioController.text.length}/500'),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: const Key('save_button'),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Bio updated successfully')),
                  );
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Test Notifications Screen
class TestNotificationsScreen extends StatelessWidget {
  const TestNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = [
      {'type': 'like', 'text': 'Sarah liked you', 'read': false},
      {'type': 'match', 'text': 'You have a new match with Emma', 'read': false},
      {'type': 'message', 'text': 'Lisa sent you a message', 'read': true},
      {'type': 'super', 'text': 'Anna super liked you', 'read': true},
    ];

    if (notifications.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('No notifications'),
              Text('When you get likes, matches, or messages, they will appear here'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            key: const Key('mark_all_read_button'),
            icon: const Icon(Icons.done_all),
            onPressed: () {},
          ),
          IconButton(
            key: const Key('notification_settings_button'),
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TestNotificationPreferencesScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        key: const Key('notifications_list'),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notif = notifications[index];
          return ListTile(
            key: Key('notification_item_$index'),
            leading: Stack(
              children: [
                Icon(
                  notif['type'] == 'like'
                      ? Icons.favorite
                      : notif['type'] == 'match'
                          ? Icons.people
                          : notif['type'] == 'super'
                              ? Icons.star
                              : Icons.message,
                ),
                if (notif['read'] == false)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      key: Key('unread_indicator_$index'),
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            title: Text(notif['text']!.toString()),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    key: const Key('profile_detail'),
                    appBar: AppBar(title: const Text('Profile')),
                    body: const Column(
                      children: [
                        Text('About'),
                        Text('Interests'),
                      ],
                    ),
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

/// Test Notification Preferences Screen
class TestNotificationPreferencesScreen extends StatelessWidget {
  const TestNotificationPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Preferences')),
      body: ListView(
        children: [
          SwitchListTile(
            key: const Key('push_notifications_toggle'),
            title: const Text('Push Notifications'),
            value: true,
            onChanged: (value) {},
          ),
          SwitchListTile(
            key: const Key('email_notifications_toggle'),
            title: const Text('Email Notifications'),
            value: true,
            onChanged: (value) {},
          ),
          SwitchListTile(
            key: const Key('likes_notification_toggle'),
            title: const Text('Likes'),
            value: true,
            onChanged: (value) {},
          ),
          SwitchListTile(
            key: const Key('matches_notification_toggle'),
            title: const Text('Matches'),
            value: true,
            onChanged: (value) {},
          ),
          SwitchListTile(
            key: const Key('messages_notification_toggle'),
            title: const Text('Messages'),
            value: true,
            onChanged: (value) {},
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              key: const Key('save_preferences_button'),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Preferences saved')),
                );
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Test Achievements Screen
class TestAchievementsScreen extends StatelessWidget {
  const TestAchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        actions: [
          IconButton(
            key: const Key('leaderboard_button'),
            icon: const Icon(Icons.leaderboard),
            onPressed: () {},
          ),
          IconButton(
            key: const Key('daily_challenges_button'),
            icon: const Icon(Icons.today),
            onPressed: () {},
          ),
          IconButton(
            key: const Key('seasonal_event_button'),
            icon: const Icon(Icons.event),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                FilterChip(label: const Text('All'), selected: true, onSelected: (v) {}),
                const SizedBox(width: 8),
                FilterChip(label: const Text('Social'), selected: false, onSelected: (v) {}),
                const SizedBox(width: 8),
                FilterChip(label: const Text('Dating'), selected: false, onSelected: (v) {}),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              key: const Key('achievements_list'),
              children: [
                ListTile(
                  key: const Key('unlocked_achievement'),
                  leading: const Icon(Icons.emoji_events, color: Colors.amber),
                  title: const Text('First Like'),
                  subtitle: Row(
                    key: const Key('achievement_progress_0'),
                    children: const [Text('1/1')],
                  ),
                ),
                ListTile(
                  key: const Key('locked_achievement'),
                  leading: const Icon(Icons.emoji_events, color: Colors.grey),
                  title: const Text('Social Butterfly'),
                  subtitle: const Text('5/10'),
                ),
                ListTile(
                  key: const Key('social_achievement'),
                  leading: const Icon(Icons.people),
                  title: const Text('Connector'),
                  subtitle: const Text('3/5'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Test Coin Shop Screen
class TestCoinShopScreen extends StatelessWidget {
  const TestCoinShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coin Shop'),
        actions: [
          IconButton(
            key: const Key('transaction_history_button'),
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: const Text('Transaction History')),
                    body: ListView(
                      key: const Key('transactions_list'),
                      children: [
                        ListTile(
                          key: const Key('transaction_item_0'),
                          title: const Text('Purchased 100 coins'),
                          subtitle: const Text('Yesterday'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            key: const Key('coin_balance'),
            padding: const EdgeInsets.all(16),
            child: const Text(
              '250 coins',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          Container(
            key: const Key('promotion_banner'),
            padding: const EdgeInsets.all(8),
            color: Colors.amber[100],
            child: const Text('20% OFF all packages!'),
          ),
          Expanded(
            child: ListView(
              key: const Key('coin_packages_list'),
              padding: const EdgeInsets.all(16),
              children: [
                for (int i = 0; i < 3; i++)
                  Card(
                    key: Key('coin_package_$i'),
                    child: ListTile(
                      title: Text('${(i + 1) * 100} coins'),
                      subtitle: Text('\$${(i + 1) * 0.99}'),
                      trailing: ElevatedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Confirm Purchase'),
                              content: Text('Buy ${(i + 1) * 100} coins for \$${(i + 1) * 0.99}?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  key: const Key('purchase_confirm_button'),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Purchase Successful!')),
                                    );
                                  },
                                  child: const Text('Buy'),
                                ),
                              ],
                            ),
                          );
                        },
                        child: const Text('Buy'),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Test Subscription Screen
class TestSubscriptionScreen extends StatelessWidget {
  const TestSubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Premium Plans')),
      body: ListView(
        key: const Key('subscription_tiers'),
        padding: const EdgeInsets.all(16),
        children: [
          _buildTierCard(context, 'Basic', '\$9.99/mo', ['Unlimited Likes']),
          _buildTierCard(context, 'Silver', '\$19.99/mo', [
            'Unlimited Likes',
            'See Who Liked You',
            'Super Likes',
          ]),
          Card(
            key: const Key('gold_tier'),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Gold',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Text('\$29.99/mo'),
                  const Divider(),
                  const Text('Unlimited Likes'),
                  const Text('See Who Liked You'),
                  const Text('Super Likes'),
                  const Text('Rewind'),
                  const Text('Boost'),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      key: const Key('subscribe_button'),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Confirm Subscription'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                key: const Key('confirm_subscription_button'),
                                onPressed: () {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Welcome to Premium!')),
                                  );
                                },
                                child: const Text('Subscribe'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: const Text('Subscribe'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierCard(BuildContext context, String name, String price, List<String> features) {
    return Card(
      key: name == 'Silver' ? const Key('silver_tier') : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(price),
            const Divider(),
            ...features.map((f) => Text(f)),
          ],
        ),
      ),
    );
  }
}

/// Test Settings Screen
class TestSettingsScreen extends StatelessWidget {
  const TestSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => SimpleDialog(
                  title: const Text('Select Language'),
                  children: [
                    SimpleDialogOption(
                      child: const Text('English'),
                      onPressed: () => Navigator.pop(context),
                    ),
                    SimpleDialogOption(
                      child: const Text('Español'),
                      onPressed: () {
                        Navigator.pop(context);
                        // Would change app language
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: const Text('About')),
                    body: ListView(
                      padding: const EdgeInsets.all(16),
                      children: const [
                        ListTile(title: Text('Version'), subtitle: Text('1.0.0')),
                        ListTile(title: Text('Privacy Policy')),
                        ListTile(title: Text('Terms of Service')),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help & Support'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: const Text('Help & Support')),
                    body: ListView(
                      children: const [
                        ListTile(title: Text('FAQ')),
                        ListTile(title: Text('Contact Us')),
                        ListTile(title: Text('Report a Problem')),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Test registration screen with consent checkboxes
class TestRegisterWithConsentScreen extends StatefulWidget {
  const TestRegisterWithConsentScreen({super.key});

  @override
  State<TestRegisterWithConsentScreen> createState() => _TestRegisterWithConsentScreenState();
}

class _TestRegisterWithConsentScreenState extends State<TestRegisterWithConsentScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _privacyPolicyAccepted = false;
  bool _termsAccepted = false;
  bool _profilingAccepted = false;
  bool _thirdPartyDataAccepted = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _canRegister => _privacyPolicyAccepted && _termsAccepted;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                key: const Key('register_email_field'),
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                key: const Key('register_password_field'),
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                key: const Key('confirm_password_field'),
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Required Consents',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              CheckboxListTile(
                key: const Key('privacy_policy_checkbox'),
                value: _privacyPolicyAccepted,
                onChanged: (value) => setState(() => _privacyPolicyAccepted = value ?? false),
                title: const Text('I accept the Privacy Policy *'),
                subtitle: GestureDetector(
                  key: const Key('privacy_policy_link'),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Opening Privacy Policy')),
                    );
                  },
                  child: const Text(
                    'Read Privacy Policy',
                    style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                  ),
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),

              CheckboxListTile(
                key: const Key('terms_checkbox'),
                value: _termsAccepted,
                onChanged: (value) => setState(() => _termsAccepted = value ?? false),
                title: const Text('I accept the Terms and Conditions *'),
                subtitle: GestureDetector(
                  key: const Key('terms_link'),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Opening Terms and Conditions')),
                    );
                  },
                  child: const Text(
                    'Read Terms and Conditions',
                    style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                  ),
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),

              const SizedBox(height: 16),
              const Text(
                'Optional Consents',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey),
              ),
              const SizedBox(height: 8),

              CheckboxListTile(
                key: const Key('profiling_checkbox'),
                value: _profilingAccepted,
                onChanged: (value) => setState(() => _profilingAccepted = value ?? false),
                title: const Text('Allow profiling for personalized experience'),
                subtitle: const Text('We use your data to improve recommendations'),
                controlAffinity: ListTileControlAffinity.leading,
              ),

              CheckboxListTile(
                key: const Key('third_party_checkbox'),
                value: _thirdPartyDataAccepted,
                onChanged: (value) => setState(() => _thirdPartyDataAccepted = value ?? false),
                title: const Text('Share data with third parties'),
                subtitle: const Text('For marketing and analytics purposes'),
                controlAffinity: ListTileControlAffinity.leading,
              ),

              const SizedBox(height: 24),

              if (!_canRegister)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Please accept Privacy Policy and Terms to continue',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  key: const Key('register_button'),
                  onPressed: _canRegister ? () {
                    if (!_emailController.text.contains('@')) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid email')),
                      );
                      return;
                    }
                    if (_passwordController.text != _confirmPasswordController.text) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Passwords do not match')),
                      );
                      return;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Registration Successful')),
                    );
                  } : null,
                  child: const Text('Register'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Test chat screen with translation support
class TestChatScreenWithTranslation extends StatefulWidget {
  const TestChatScreenWithTranslation({super.key});

  @override
  State<TestChatScreenWithTranslation> createState() => _TestChatScreenWithTranslationState();
}

class _TestChatScreenWithTranslationState extends State<TestChatScreenWithTranslation> {
  final _messageController = TextEditingController();
  final List<TestMessage> _messages = [
    TestMessage(
      id: '1',
      content: 'Ciao! Come stai?',
      isCurrentUser: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    TestMessage(
      id: '2',
      content: 'Hello! I am fine, thanks!',
      isCurrentUser: true,
      timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
    ),
    TestMessage(
      id: '3',
      content: 'Che bel tempo oggi!',
      isCurrentUser: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
    ),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _translateMessage(int index) {
    setState(() {
      final msg = _messages[index];
      if (!msg.isTranslated) {
        String translated;
        if (msg.content == 'Ciao! Come stai?') {
          translated = 'Hello! How are you?';
        } else if (msg.content == 'Che bel tempo oggi!') {
          translated = 'What nice weather today!';
        } else {
          translated = 'Translated: ${msg.content}';
        }
        _messages[index] = msg.copyWith(
          translatedContent: translated,
          isTranslated: true,
        );
      }
    });
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _messages.add(TestMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: _messageController.text.trim(),
        isCurrentUser: true,
        timestamp: DateTime.now(),
      ));
      _messageController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Marco'),
            Text('Online', style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
        actions: [
          IconButton(
            key: const Key('translation_settings_button'),
            icon: const Icon(Icons.translate),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Translation Settings'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        key: const Key('auto_translate_toggle'),
                        title: const Text('Auto-translate messages'),
                        trailing: Switch(
                          value: true,
                          onChanged: (value) {},
                        ),
                      ),
                      ListTile(
                        key: const Key('download_language_button'),
                        title: const Text('Download Italian'),
                        trailing: const Icon(Icons.download),
                        onTap: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Downloading Italian language pack...')),
                          );
                        },
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              key: const Key('message_list'),
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return TestMessageBubble(
                  key: Key('message_bubble_$index'),
                  message: message,
                  onTranslate: () => _translateMessage(index),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('message_input'),
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  key: const Key('send_button'),
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Test message model
class TestMessage {
  final String id;
  final String content;
  final bool isCurrentUser;
  final DateTime timestamp;
  final String? translatedContent;
  final bool isTranslated;

  TestMessage({
    required this.id,
    required this.content,
    required this.isCurrentUser,
    required this.timestamp,
    this.translatedContent,
    this.isTranslated = false,
  });

  TestMessage copyWith({
    String? id,
    String? content,
    bool? isCurrentUser,
    DateTime? timestamp,
    String? translatedContent,
    bool? isTranslated,
  }) {
    return TestMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
      timestamp: timestamp ?? this.timestamp,
      translatedContent: translatedContent ?? this.translatedContent,
      isTranslated: isTranslated ?? this.isTranslated,
    );
  }
}

/// Test message bubble widget
class TestMessageBubble extends StatelessWidget {
  final TestMessage message;
  final VoidCallback? onTranslate;

  const TestMessageBubble({
    super.key,
    required this.message,
    this.onTranslate,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showContextMenu(context),
      child: Align(
        alignment: message.isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(12),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          decoration: BoxDecoration(
            color: message.isCurrentUser ? Colors.green[100] : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message.content),
              if (message.isTranslated && message.translatedContent != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.translate, size: 12, color: Colors.blue[700]),
                          const SizedBox(width: 4),
                          Text(
                            'Translated',
                            style: TextStyle(fontSize: 10, color: Colors.blue[700]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message.translatedContent!,
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const Key('copy_message_button'),
              leading: const Icon(Icons.copy),
              title: const Text('Copy'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Message copied')),
                );
              },
            ),
            if (!message.isTranslated)
              ListTile(
                key: const Key('translate_message_button'),
                leading: const Icon(Icons.translate),
                title: const Text('Translate'),
                onTap: () {
                  Navigator.pop(context);
                  onTranslate?.call();
                },
              ),
            ListTile(
              key: const Key('forward_message_button'),
              leading: const Icon(Icons.forward),
              title: const Text('Forward'),
              onTap: () => Navigator.pop(context),
            ),
            if (message.isCurrentUser)
              ListTile(
                key: const Key('delete_message_button'),
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () => Navigator.pop(context),
              ),
          ],
        ),
      ),
    );
  }
}

/// Helper to pump the test app
Future<void> pumpTestApp(
  WidgetTester tester, {
  Widget? child,
}) async {
  await tester.pumpWidget(
    TestApp(
      child: child ?? const TestLoginScreen(),
    ),
  );
  await tester.pumpAndSettle();
}
