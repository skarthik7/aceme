import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:aceme/theme_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PlannerPage extends StatefulWidget {
  @override
  _PlannerPageState createState() => _PlannerPageState();
}

class _PlannerPageState extends State<PlannerPage> {
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  Future<void> _getCurrentUser() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _userEmail = user.email;
      });
      print('User email: $_userEmail'); // Debug print to check user email
    }
  }

  /// Show a dialog to add a new task
  void _showAddTaskDialog() {
    TextEditingController titleController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();
    DateTime? selectedDate;
    String selectedCategory = 'General';
    String selectedPriority = 'Medium';
    bool showTitleError = false;
    bool showDateError = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 20,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text("Task Title", style: TextStyle(fontSize: 16)),
                      Text(" *", style: TextStyle(color: Colors.red, fontSize: 16)),
                    ],
                  ),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      hintText: "Enter task title",
                      errorText: showTitleError && titleController.text.isEmpty ? 'Title is required' : null,
                    ),
                  ),
                  SizedBox(height: 10),
                  TextField(controller: descriptionController, decoration: InputDecoration(labelText: 'Description (Optional)')),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Text("Due Date", style: TextStyle(fontSize: 16)),
                      Text(" *", style: TextStyle(color: Colors.red, fontSize: 16)),
                    ],
                  ),
                  TextButton(
                    onPressed: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (pickedDate != null) {
                        setModalState(() {
                          selectedDate = pickedDate;
                          showDateError = false;
                        });
                      }
                    },
                    child: Text(
                      selectedDate == null ? 'Select Date' : DateFormat('yyyy-MM-dd').format(selectedDate!),
                      style: TextStyle(color: selectedDate == null ? Colors.grey : Colors.black),
                    ),
                  ),
                  if (showDateError && selectedDate == null)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Due date is required', style: TextStyle(color: Colors.red, fontSize: 12)),
                      ),
                    ),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    onChanged: (value) => setModalState(() => selectedCategory = value!),
                    items: ['General', 'Homework', 'Exam Revision', 'Project'].map((category) => DropdownMenuItem(value: category, child: Text(category))).toList(),
                    decoration: InputDecoration(labelText: 'Category'),
                  ),
                  DropdownButtonFormField<String>(
                    value: selectedPriority,
                    onChanged: (value) => setModalState(() => selectedPriority = value!),
                    items: ['Low', 'Medium', 'High'].map((priority) => DropdownMenuItem(value: priority, child: Text(priority))).toList(),
                    decoration: InputDecoration(labelText: 'Priority Level'),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      setModalState(() {
                        showTitleError = titleController.text.isEmpty;
                        showDateError = selectedDate == null;
                      });
                      if (!showTitleError && !showDateError) {
                        FirebaseFirestore.instance.collection('tasks').add({
                          'email': _userEmail,
                          'title': titleController.text,
                          'description': descriptionController.text.isNotEmpty ? descriptionController.text : 'No Description',
                          'dueDate': selectedDate!,
                          'category': selectedCategory,
                          'priority': selectedPriority,
                          'completed': false,
                          'createdAt': FieldValue.serverTimestamp(),
                        });
                        Navigator.pop(context);
                      }
                    },
                    child: Text('Add Task'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Planner'),
        backgroundColor: Colors.blue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(30),
          ),
        ),
      ),
      body: _userEmail == null
          ? Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('tasks')
                  .where('email', isEqualTo: _userEmail)
                  .orderBy('createdAt')
                  .snapshots(),
              builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("No tasks yet. Add some!"));
                }

                final tasks = snapshot.data!.docs;
                print('Tasks: ${tasks.length}');

                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    var task = tasks[index];
                    print('Task email: ${task['email']}');
                    return Dismissible(
                      key: Key(task.id),
                      background: Container(
                        color: Colors.green,
                        alignment: Alignment.centerLeft,
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Icon(Icons.check, color: Colors.white),
                      ),
                      secondaryBackground: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.startToEnd) {
                          task.reference.update({'completed': true});
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Task '${task['title']}' marked as done")),
                          );
                          return false;
                        } else if (direction == DismissDirection.endToStart) {
                          task.reference.delete();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Task '${task['title']}' deleted")),
                          );
                          return true;
                        }
                        return false;
                      },
                      child: Card(
                        child: ListTile(
                          title: Text(
                            task['title'],
                            style: TextStyle(
                              decoration: task['completed'] ? TextDecoration.lineThrough : TextDecoration.none,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("📌 ${task['description']}"),
                              Text("📅 Due: ${DateFormat('yyyy-MM-dd').format(task['dueDate'].toDate())}"),
                              Text("📂 Category: ${task['category']}"),
                              Text("⚡ Priority: ${task['priority']}"),
                            ],
                          ),
                          leading: Checkbox(
                            value: task['completed'],
                            onChanged: (bool? value) => task.reference.update({'completed': value}),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        child: Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
    );
  }
}