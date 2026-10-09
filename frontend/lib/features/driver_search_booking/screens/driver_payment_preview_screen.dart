import 'package:flutter/material.dart';
import '../../driver_search/models/parking_map_facility.dart';

class DriverPaymentPreviewScreen extends StatelessWidget {
  const DriverPaymentPreviewScreen({super.key, required this.facility, required this.bay, required this.arrival, required this.hours, required this.vehicle});
  final ParkingMapFacility facility;
  final Map<String,dynamic> bay;
  final DateTime arrival;
  final int hours;
  final String vehicle;
  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF1E3D70);
    final parking = facility.ratePerHour * hours;
    final total = parking + facility.reservationFee;
    return Scaffold(backgroundColor: const Color(0xFFF4F6FB), appBar: AppBar(title: const Text('Payment review'), backgroundColor: navy, foregroundColor: Colors.white), body: SafeArea(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(facility.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 19)),
      const SizedBox(height: 16), Text('Bay: ${bay['label']} · ${bay['level'] ?? 'Ground'}'),
      Text('Vehicle: $vehicle'), Text('Arrival: ${arrival.toLocal()}'), Text('Duration: $hours hours'),
      const SizedBox(height: 22), Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(children: [
        _line('Parking', parking), _line('Reservation fee', facility.reservationFee), const Divider(), _line('Estimated total', total),
      ]))),
      const SizedBox(height: 18), const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Payment is not connected yet. This screen does not charge a card, create a paid payment record, or confirm a reservation. A secure server-side booking and payment integration is required.'))),
      const Spacer(), ElevatedButton(onPressed: null, child: Text('Payment integration pending')),
    ]))));
  }
  Widget _line(String name, double amount) => Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(name), Text('Rs ${amount.toStringAsFixed(2)}')]));
}
