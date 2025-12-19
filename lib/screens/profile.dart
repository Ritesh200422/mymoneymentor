// lib/screens/profile_page.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _picker = ImagePicker();
  final _auth = FirebaseAuth.instance;
  final _fs = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  bool _loading = true;
  bool _saving = false;

  // user fields
  String _uid = '';
  String _name = '';
  String _email = '';
  String _phone = '';
  String? _photoUrl;
  int _bookmarks = 0;
  double _avgScore = 0.0;
  int _quizzesTaken = 0;
  int _streak = 0;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() => _loading = true);
    final user = _auth.currentUser;
    if (user == null) {
      // Not signed in — send to login
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return;
    }
    _uid = user.uid;
    _name = user.displayName ?? '';
    _email = user.email ?? '';
    // load Firestore profile doc
    final doc = await _fs.collection('users').doc(_uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      _phone = data['phone'] ?? '';
      _photoUrl = data['photoUrl'];
      _bookmarks = data['bookmarks'] ?? 0;
      _quizzesTaken = data['quizzesTaken'] ?? 0;
      _avgScore = (data['avgScore'] ?? 0).toDouble();
      _streak = data['streak'] ?? 0;
      // if name empty locally, use firestore
      if (_name.isEmpty) _name = data['name'] ?? _name;
    } else {
      // create initial doc
      await _fs.collection('users').doc(_uid).set({
        'name': _name,
        'email': _email,
        'phone': _phone,
        'photoUrl': _photoUrl,
        'bookmarks': _bookmarks,
        'quizzesTaken': _quizzesTaken,
        'avgScore': _avgScore,
        'streak': _streak,
      });
    }
    setState(() => _loading = false);
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    final XFile? file = await _picker.pickImage(source: source, imageQuality: 80);
    if (file == null) return;
    setState(() => _saving = true);
    try {
      // upload to Firebase Storage under profiles/{uid}.jpg
      final ref = _storage.ref().child('profiles/$_uid.jpg');
      await ref.putFile(File(file.path));
      final url = await ref.getDownloadURL();
      // save in firestore and auth profile
      await _fs.collection('users').doc(_uid).set({'photoUrl': url}, SetOptions(merge: true));
      await _auth.currentUser?.updatePhotoURL(url);
      setState(() => _photoUrl = url);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile photo updated')));
    } catch (e) {
      debugPrint('upload error: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _removePhoto() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Remove photo?'),
        content: const Text('This will remove your profile photo.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Remove')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _saving = true);
    try {
      final ref = _storage.ref().child('profiles/$_uid.jpg');
      // delete from storage (if exists)
      try {
        await ref.delete();
      } catch (_) {}
      // remove from firestore & auth
      await _fs.collection('users').doc(_uid).set({'photoUrl': null}, SetOptions(merge: true));
      await _auth.currentUser?.updatePhotoURL(null);
      setState(() => _photoUrl = null);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile photo removed')));
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    try {
      // update auth displayName
      await _auth.currentUser?.updateDisplayName(_name);
      // update firestore
      await _fs.collection('users').doc(_uid).set({
        'name': _name,
        'phone': _phone,
        'bookmarks': _bookmarks,
        'quizzesTaken': _quizzesTaken,
        'avgScore': _avgScore,
        'streak': _streak,
      }, SetOptions(merge: true));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _changePassword() async {
    // Show dialog asking current+new password for reauth
    final res = await showDialog<Map<String, String>?>(
      context: context,
      builder: (c) {
        final currCtrl = TextEditingController();
        final newCtrl = TextEditingController();
        return AlertDialog(
          title: const Text('Change password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: currCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Current password')),
              TextField(controller: newCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'New password')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(c, {'current': currCtrl.text, 'new': newCtrl.text}), child: const Text('Change')),
          ],
        );
      },
    );

    if (res == null) return;
    final current = res['current'] ?? '';
    final next = res['new'] ?? '';
    if (current.isEmpty || next.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter both fields')));
      return;
    }

    try {
      setState(() => _saving = true);
      final user = _auth.currentUser!;
      if (user.email == null) throw 'Email not available for reauthentication';
      final cred = EmailAuthProvider.credential(email: user.email!, password: current);
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(next);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Password change failed: $e')));
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete account'),
        content: const Text('Deleting your account will remove your data. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;

    // For safety: require reauth with current password
    final pw = await _askForPassword();
    if (pw == null) return;
    try {
      setState(() => _saving = true);
      final user = _auth.currentUser!;
      final cred = EmailAuthProvider.credential(email: user.email!, password: pw);
      await user.reauthenticateWithCredential(cred);
      // delete storage file
      try {
        await _storage.ref().child('profiles/$_uid.jpg').delete();
      } catch (_) {}
      // delete firestore doc
      await _fs.collection('users').doc(_uid).delete();
      // delete auth user
      await user.delete();
      // navigate to login
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<String?> _askForPassword() async {
    final ctrl = TextEditingController();
    final res = await showDialog<String?>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Confirm password'),
        content: TextField(controller: ctrl, obscureText: true, decoration: const InputDecoration(labelText: 'Current password')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(c, ctrl.text), child: const Text('Confirm')),
        ],
      ),
    );
    return res;
  }

  Future<void> _logout() async {
    await _auth.signOut();
    if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
  }

  // quick inline edit helper
  Future<void> _editField(String title, String initial, Function(String) onSave) async {
    final ctrl = TextEditingController(text: initial);
    final res = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Edit $title'),
        content: TextField(controller: ctrl, decoration: InputDecoration(labelText: title)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('Save')),
        ],
      ),
    );
    if (res == true) onSave(ctrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Avatar + edit controls
            Stack(
              children: [
                CircleAvatar(
                  radius: 56,
                  backgroundColor: Colors.grey.shade800,
                  backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) as ImageProvider : null,
                  child: _photoUrl == null
                      ? Text(_name.isNotEmpty ? _name[0].toUpperCase() : 'U', style: const TextStyle(fontSize: 32))
                      : null,
                ),
                Positioned(
                  right: -6,
                  bottom: -6,
                  child: Row(
                    children: [
                      FloatingActionButton.small(
                        heroTag: 'editPic',
                        onPressed: () => _showImageSource(),
                        child: const Icon(Icons.camera_alt, size: 18),
                      ),
                      const SizedBox(width: 8),
                      if (_photoUrl != null)
                        FloatingActionButton.small(
                          heroTag: 'removePic',
                          backgroundColor: Colors.redAccent,
                          onPressed: _removePhoto,
                          child: const Icon(Icons.delete, size: 18),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // name / email / phone
            Text(_name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(_email, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
            const SizedBox(height: 12),
            // edit profile buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _editField('Name', _name, (val) => setState(() => _name = val)),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Profile'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _saveProfile,
                  icon: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
                  label: const Text('Save'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statBox('Bookmarks', '$_bookmarks', Icons.bookmark),
                _statBox('Quizzes', '$_quizzesTaken', Icons.quiz),
                _statBox('Accuracy', '${_avgScore.toStringAsFixed(0)}%', Icons.insights),
                _statBox('Streak', '$_streak days', Icons.local_fire_department),
              ],
            ),

            const SizedBox(height: 20),

            // editable phone
            ListTile(
              leading: const Icon(Icons.phone),
              title: Text(_phone.isEmpty ? 'Add phone number' : _phone),
              trailing: const Icon(Icons.edit),
              onTap: () => _editField('Phone', _phone, (val) => setState(() => _phone = val)),
            ),

            const SizedBox(height: 6),
            // Dark mode toggle (global via provider)

            const SizedBox(height: 6),
            // Change password / delete / logout
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Change password'),
              onTap: _changePassword,
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
              title: const Text('Delete account', style: TextStyle(color: Colors.redAccent)),
              onTap: _deleteAccount,
            ),
            const SizedBox(height: 24),

            // Save changes permanently
            ElevatedButton(
              onPressed: _saveProfile,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 18),
                child: Text('Save changes', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _statBox(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 28, color: Colors.greenAccent),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Future<void> _showImageSource() async {
    final choice = await showModalBottomSheet<ImageSource?>(
      context: context,
      builder: (c) => SafeArea(
        child: Wrap(
          children: [
            ListTile(leading: const Icon(Icons.photo_library), title: const Text('Gallery'), onTap: () => Navigator.pop(c, ImageSource.gallery)),
            ListTile(leading: const Icon(Icons.camera_alt), title: const Text('Camera'), onTap: () => Navigator.pop(c, ImageSource.camera)),
          ],
        ),
      ),
    );
    if (choice != null) await _pickAndUploadImage(choice);
  }
}
