import 'package:flutter/material.dart';

import '../../core/content.dart';
import '../widgets.dart';

/// Birth-preparation checklist and plan (MA-13).
class BirthPlanScreen extends StatefulWidget {
  const BirthPlanScreen({super.key});
  @override
  State<BirthPlanScreen> createState() => _BirthPlanScreenState();
}

class _BirthPlanScreenState extends State<BirthPlanScreen> {
  late final TextEditingController transport, companion, contact;

  @override
  void initState() {
    super.initState();
    final plan = context.appRead.birthPlan;
    transport = TextEditingController(text: plan['transport'] as String? ?? '');
    companion = TextEditingController(text: plan['companion'] as String? ?? '');
    contact = TextEditingController(text: plan['emergency_contact'] as String? ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final s = context.app;
    final plan = s.birthPlan;
    final ready = {...(plan['items_ready'] as List).cast<String>()};
    return Scaffold(
      appBar: AppBar(title: Text(context.t('My birth plan', 'Mpango wangu wa kujifungua')), actions: const [EmergencyButton()]),
      body: Pad(
        children: [
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                for (final (k, label) in birthReady)
                  CheckboxListTile(
                    value: ready.contains(k),
                    title: Text(context.tx(label)),
                    onChanged: (v) => s.saveBirthPlan({
                      'items_ready': (v == true ? ({...ready, k}) : (ready..remove(k))).toList(),
                    }),
                  ),
              ],
            ),
          ),
          SectionTitle(context.t('Details', 'Maelezo')),
          Labeled(label: context.t('How will you travel, day or night?', 'Utasafiri vipi, mchana au usiku?'), child: TextField(
            controller: transport,
            maxLength: 200,
            decoration: InputDecoration(),
          )),
          const Gap(12),
          Labeled(label: context.t('Who will go with you?', 'Nani atakusindikiza?'), child: TextField(
            controller: companion,
            maxLength: 120,
            decoration: InputDecoration(),
          )),
          const Gap(12),
          Labeled(label: context.t('Emergency contact phone', 'Simu ya mtu wa dharura'), child: TextField(
            controller: contact,
            maxLength: 40,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(),
          )),
          const Gap(16),
          FilledButton(
            onPressed: () {
              s.saveBirthPlan({'transport': transport.text.trim(), 'companion': companion.text.trim(), 'emergency_contact': contact.text.trim()});
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t('Birth plan saved', 'Mpango umehifadhiwa'))));
            },
            child: Text(context.t('Save', 'Hifadhi')),
          ),
        ],
      ),
    );
  }
}
