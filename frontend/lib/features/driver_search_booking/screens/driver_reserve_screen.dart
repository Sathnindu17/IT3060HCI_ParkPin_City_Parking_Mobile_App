import 'package:flutter/material.dart';
import '../../driver_search/models/parking_map_facility.dart';
import 'driver_select_bay_screen.dart';

class DriverReserveScreen extends StatefulWidget {
  const DriverReserveScreen({super.key, required this.facility, required this.vehicle, required this.hours});
  final ParkingMapFacility facility;
  final String vehicle;
  final int hours;
  @override
  State<DriverReserveScreen> createState() => _DriverReserveScreenState();
}
class _DriverReserveScreenState extends State<DriverReserveScreen> {
  static const navy = Color(0xFF1E3D70);
  static const orange = Color(0xFFFFA51F);
  late int hours;
  late DateTime arrival;
  @override
  void initState() { super.initState(); hours = widget.hours; arrival = DateTime.now().add(const Duration(minutes: 30)); }
  Future<void> chooseArrival() async {
    final day = await showDatePicker(context: context, initialDate: arrival, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 30)));
    if (day == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(arrival));
    if (time == null || !mounted) return;
    final next = DateTime(day.year, day.month, day.day, time.hour, time.minute);
    if (!next.isAfter(DateTime.now())) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Choose a future arrival time.'))); return; }
    setState(() => arrival = next);
  }
  @override
  Widget build(BuildContext context) {
    final parking = widget.facility.ratePerHour * hours;
    final total = parking + widget.facility.reservationFee;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(title: const Text('Reserve'), backgroundColor: navy, foregroundColor: Colors.white),
      body: SafeArea(child: Column(children: [
        Expanded(child: ListView(padding: const EdgeInsets.all(18), children: [
          Text(widget.facility.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: navy)),
          const SizedBox(height: 22),
          const Text('Date & arrival'),
          Card(child: ListTile(title: Text(MaterialLocalizations.of(context).formatMediumDate(arrival)), subtitle: Text(TimeOfDay.fromDateTime(arrival).format(context)), trailing: const Icon(Icons.calendar_today), onTap: chooseArrival)),
          const SizedBox(height: 18), const Text('Duration'),
          Wrap(spacing: 8, children: [for (final h in [1,2,4,8]) ChoiceChip(label: Text('$h ${h == 1 ? 'hour' : 'hours'}'), selected: hours == h, onSelected: (_) => setState(() => hours = h))]),
          const SizedBox(height: 18), Text('Vehicle type: ${widget.vehicle}'),
          const SizedBox(height: 18), const Text('Estimated price', style: TextStyle(fontWeight: FontWeight.bold, color: navy)),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
            _line('Parking ($hours h)', parking), _line('Reservation fee', widget.facility.reservationFee), const Divider(), _line('Estimated total', total),
            const SizedBox(height: 12), const Text('Estimate only. Final pricing must be validated on the server before payment.', style: TextStyle(fontSize: 12)),
          ]))),
        ])),
        Padding(padding: const EdgeInsets.all(16), child: SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: orange, foregroundColor: navy),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DriverSelectBayScreen(facility: widget.facility, vehicle: widget.vehicle, hours: hours, arrival: arrival))),
          child: const Text('Choose specific bay'),
        ))),
      ])),
    );
  }
  Widget _line(String label, double price) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label), Text('Rs ${price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: navy))]));
}
