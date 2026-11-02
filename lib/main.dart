import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() { WidgetsFlutterBinding.ensureInitialized(); runApp(const DailyTaskPro()); }

class DailyTaskPro extends StatefulWidget {
  const DailyTaskPro({super.key});
  @override State<DailyTaskPro> createState() => _DailyTaskProState();
}
class _DailyTaskProState extends State<DailyTaskPro> {
  bool dark = false;
  @override Widget build(BuildContext context) => MaterialApp(
    title: 'Daily Task Pro', debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xff5267d8), scaffoldBackgroundColor: const Color(0xfff6f7fc)),
    darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark, colorSchemeSeed: const Color(0xff5267d8)),
    themeMode: dark ? ThemeMode.dark : ThemeMode.light,
    home: Home(onTheme: () => setState(() => dark = !dark), dark: dark),
  );
}
class Home extends StatefulWidget {
  final VoidCallback onTheme; final bool dark;
  const Home({super.key, required this.onTheme, required this.dark});
  @override State<Home> createState() => _HomeState();
}
class _HomeState extends State<Home> {
  int tab = 0; bool urdu = false; bool loaded = false;
  List<Map<String,dynamic>> expenses = [], loans = [], tasks = [];
  String tr(String en, String ur) => urdu ? ur : en;
  @override void initState() { super.initState(); load(); }
  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    List<Map<String,dynamic>> read(String key) {
      try { return (jsonDecode(p.getString(key) ?? '[]') as List).map((e) => Map<String,dynamic>.from(e as Map)).toList(); }
      catch (_) { return []; }
    }
    if (!mounted) return;
    setState(() { expenses = read('expenses'); loans = read('loans'); tasks = read('tasks'); urdu = p.getBool('urdu') ?? false; loaded = true; });
  }
  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('expenses', jsonEncode(expenses));
    await p.setString('loans', jsonEncode(loans));
    await p.setString('tasks', jsonEncode(tasks));
    await p.setBool('urdu', urdu);
  }
  void add(List<Map<String,dynamic>> target, Map<String,dynamic> item) { setState(() => target.insert(0,item)); save(); }
  void remove(List<Map<String,dynamic>> target, int index) { setState(() => target.removeAt(index)); save(); }
  double total(String type) => expenses.where((e) => e['type'] == type && (e['date'] as String).substring(0,7) == DateTime.now().toIso8601String().substring(0,7)).fold(0.0,(sum,e)=>sum+(e['amount'] as num).toDouble());
  Widget metric(String title, double value, IconData icon) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[Icon(icon,color: Theme.of(context).colorScheme.primary),const SizedBox(height:12),Text(title),const SizedBox(height:5),Text('PKR ${value.toStringAsFixed(0)}',style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold))])));
  Widget dashboard() => ListView(padding:const EdgeInsets.all(14),children:[
    Text(tr('Your month at a glance','اس ماہ کا خلاصہ'),style:Theme.of(context).textTheme.titleLarge),
    const SizedBox(height:12),
    Row(children:[Expanded(child:metric(tr('Income','آمدنی'),total('Income'),Icons.trending_up)),Expanded(child:metric(tr('Expenses','اخراجات'),total('Expense'),Icons.payments))]),
    Row(children:[Expanded(child:metric(tr('Savings','بچت'),total('Income')-total('Expense')-total('Investment'),Icons.savings)),Expanded(child:metric(tr('Investments','سرمایہ کاری'),total('Investment'),Icons.show_chart))]),
    Card(child:ListTile(leading:const Icon(Icons.account_balance_wallet),title:Text(tr('Outstanding loans','باقی قرضے')),subtitle:Text('${loans.where((e)=>e['settled'] != true).length} ${tr('open records','کھلے ریکارڈ')}'))),
    Card(child:ListTile(leading:const Icon(Icons.task_alt),title:Text(tr('Tasks completed','مکمل کام')),subtitle:Text('${tasks.where((e)=>e['done'] == true).length} / ${tasks.length}'))),
  ]);
  Widget expensePage() => ListView(children:[...expenses.asMap().entries.map((entry) {final e=entry.value; return Card(child:ListTile(leading:Icon(e['type']=='Income'?Icons.add_circle:Icons.remove_circle),title:Text('${e['category']} · PKR ${e['amount']}'),subtitle:Text('${e['type']} · ${e['method']} · ${e['date']}\n${e['note'] ?? ''}'),isThreeLine:true,trailing:IconButton(icon:const Icon(Icons.delete_outline),onPressed:()=>remove(expenses,entry.key))));})]);
  Widget loanPage() => ListView(children:[...loans.asMap().entries.map((entry) {final e=entry.value;return Card(child:CheckboxListTile(value:e['settled']==true,onChanged:(v){setState(()=>e['settled']=v);save();},title:Text('${e['person']} · PKR ${e['amount']}'),subtitle:Text('${e['direction']} · ${e['method']}\n${tr('Due','واپسی')}: ${e['due']} · ${e['note']??''}'),secondary:IconButton(icon:const Icon(Icons.delete_outline),onPressed:()=>remove(loans,entry.key))));})]);
  Widget taskPage() => ListView(children:[...tasks.asMap().entries.map((entry) {final e=entry.value;return Card(child:CheckboxListTile(value:e['done']==true,onChanged:(v){setState(()=>e['done']=v);save();},title:Text('${e['title']}'),subtitle:Text('${e['date']} · ${e['priority']}'),secondary:IconButton(icon:const Icon(Icons.delete_outline),onPressed:()=>remove(tasks,entry.key))));})]);
  Widget profilePage() => ListView(padding:const EdgeInsets.all(12),children:[
    Card(child:SwitchListTile(title:Text(tr('Urdu language','اردو زبان')),value:urdu,onChanged:(v){setState(()=>urdu=v);save();})),
    Card(child:SwitchListTile(title:Text(tr('Dark mode','ڈارک موڈ')),value:widget.dark,onChanged:(_)=>widget.onTheme())),
    const Card(child:ListTile(leading:Icon(Icons.info_outline),title:Text('Starter build — local device storage'),subtitle:Text('Google sign-in, encrypted storage, cloud backup, notifications and receipt uploads require additional implementation. Do not store sensitive financial data in this prototype.'))),
  ]);
  Future<void> newEntry() async {
    final fields = <String,TextEditingController>{};
    TextEditingController ctl(String key) => fields.putIfAbsent(key,()=>TextEditingController());
    String type='Expense', method='Cash', direction='Given', priority='Medium';
    final form=GlobalKey<FormState>();
    final result=await showDialog<Map<String,dynamic>>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,update)=>AlertDialog(
      title:Text(tab==1?tr('Add transaction','نیا اندراج'):tab==2?tr('Add loan','قرض شامل کریں'):tr('Add task','کام شامل کریں')),
      content:SingleChildScrollView(child:Form(key:form,child:Column(mainAxisSize:MainAxisSize.min,children:[
        if(tab==1) DropdownButtonFormField<String>(value:type,items:['Expense','Income','Investment'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>update(()=>type=v!)),
        if(tab==2) DropdownButtonFormField<String>(value:direction,items:['Given','Taken'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>update(()=>direction=v!)),
        TextFormField(controller:ctl(tab==1?'category':tab==2?'person':'title'),decoration:InputDecoration(labelText:tab==1?'Category (Food, Bills, Travel...)':tab==2?'Person / beneficiary':'Task title'),validator:(v)=>v==null||v.trim().isEmpty?'Required':null),
        if(tab!=3) TextFormField(controller:ctl('amount'),keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Amount (PKR)'),validator:(v)=>double.tryParse(v??'')==null||double.parse(v!)<=0?'Enter a positive number':null),
        if(tab!=3) DropdownButtonFormField<String>(value:method,items:['Cash','Online'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>update(()=>method=v!)),
        if(tab==3) DropdownButtonFormField<String>(value:priority,items:['Low','Medium','High'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>update(()=>priority=v!)),
        if(tab==2) TextFormField(controller:ctl('due'),decoration:const InputDecoration(labelText:'Due date (YYYY-MM-DD)'),validator:(v)=>DateTime.tryParse(v??'')==null?'Enter a valid date':null),
        if(tab!=3) TextFormField(controller:ctl('note'),decoration:const InputDecoration(labelText:'Notes / tags (optional)')),
      ]))),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Cancel')),FilledButton(onPressed:(){if(form.currentState!.validate()){Navigator.pop(ctx,{
        ...fields.map((k,v)=>MapEntry(k,v.text.trim())), 'amount':double.tryParse(ctl('amount').text)??0.0,'type':type,'method':method,'direction':direction,'priority':priority,'date':DateTime.now().toIso8601String(),'done':false,'settled':false,
      });}},child:const Text('Save'))],
    )));
    for(final c in fields.values){c.dispose();}
    if(result!=null){add(tab==1?expenses:tab==2?loans:tasks,result);}
  }
  @override Widget build(BuildContext context) {
    final titles=[tr('Dashboard','ڈیش بورڈ'),tr('Expenses','اخراجات'),tr('Loans','قرضے'),tr('Tasks','کام'),tr('Profile','پروفائل')];
    return Scaffold(appBar:AppBar(title:Text('Daily Task Pro · ${titles[tab]}'),backgroundColor:Theme.of(context).colorScheme.surface),
      body:!loaded?const Center(child:CircularProgressIndicator()):IndexedStack(index:tab,children:[dashboard(),expensePage(),loanPage(),taskPage(),profilePage()]),
      floatingActionButton:tab>=1&&tab<=3?FloatingActionButton.extended(onPressed:newEntry,icon:const Icon(Icons.add),label:Text(tr('Add new','نیا شامل کریں'))):null,
      bottomNavigationBar:NavigationBar(selectedIndex:tab,onDestinationSelected:(i)=>setState(()=>tab=i),destinations:[
        NavigationDestination(icon:const Icon(Icons.dashboard_outlined),label:tr('Home','ہوم')),
        NavigationDestination(icon:const Icon(Icons.wallet_outlined),label:tr('Money','رقم')),
        NavigationDestination(icon:const Icon(Icons.handshake_outlined),label:tr('Loans','قرض')),
        NavigationDestination(icon:const Icon(Icons.check_circle_outline),label:tr('Tasks','کام')),
        NavigationDestination(icon:const Icon(Icons.person_outline),label:tr('Profile','پروفائل')),
      ]),
    );
  }
}
