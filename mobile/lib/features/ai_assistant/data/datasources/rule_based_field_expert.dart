import '../../domain/entities/troubleshooting_advice.dart';

class RuleBasedFieldExpert {
  static TroubleshootingAdvice diagnose(String query) {
    final lower = query.toLowerCase();

    // 1. HVAC / Cooling / Refrigeration
    if (lower.contains('ac') ||
        lower.contains('cool') ||
        lower.contains('refrigeran') ||
        lower.contains('chiller') ||
        lower.contains('air')) {
      return TroubleshootingAdvice(
        query: query,
        possibleCauses: const [
          'Severely clogged or dirty air intake filter restricting airflow',
          'Low refrigerant charge due to suction valve micro-leak',
          'Condenser coil fouling preventing effective heat rejection',
          'Faulty blower run capacitor or slipping drive belt',
        ],
        recommendedChecks: const [
          'Inspect filter differential pressure or physical dust buildup',
          'Measure suction and discharge refrigerant pressures with manifold gauges',
          'Check temperature split across evaporator coil (target 18°F - 22°F)',
          'Verify condenser fan motor rotation and capacitor microfarad rating',
        ],
        safetyNotes:
            'CAUTION: Lockout/Tagout (LOTO) all high-voltage power disconnects before opening electrical plenum. Wear protective eyewear and gloves when connecting refrigerant gauges.',
        timestamp: DateTime.now(),
        source: 'Field Diagnostics Expert (Offline Engine)',
      );
    }

    // 2. Solar Inverter / Electrical Faults
    if (lower.contains('solar') ||
        lower.contains('inverter') ||
        lower.contains('ground fault') ||
        lower.contains('voltage') ||
        lower.contains('trip')) {
      return TroubleshootingAdvice(
        query: query,
        possibleCauses: const [
          'DC ground fault due to compromised solar string insulation',
          'Grid over-voltage condition during low local utility load',
          'Overheating power semiconductors caused by clogged heatsink fans',
          'Loose termination on DC disconnect or AC combiner breaker',
        ],
        recommendedChecks: const [
          'Measure open-circuit string voltage (Voc) and verify polarity',
          'Perform insulation resistance test (Megger) from positive/negative to ground',
          'Inspect inverter cooling exhaust vents and fan operation under load',
          'Check AC grid voltage and frequency within IEEE 1547 parameters',
        ],
        safetyNotes:
            'DANGER: High-voltage DC circuits cannot be turned off while solar panels receive sunlight. Use rated arc-flash PPE (minimum Category 2) and insulated 1000V tools.',
        timestamp: DateTime.now(),
        source: 'Field Diagnostics Expert (Offline Engine)',
      );
    }

    // 3. Motor / Pump / Starter
    if (lower.contains('motor') ||
        lower.contains('pump') ||
        lower.contains('overload') ||
        lower.contains('starter') ||
        lower.contains('bearing')) {
      return TroubleshootingAdvice(
        query: query,
        possibleCauses: const [
          'Phase imbalance or single-phasing causing thermal overload trip',
          'Mechanical binding or worn bearings increasing motor torque load',
          'Loose contactor power lugs creating excessive resistance and heat',
          'Undersized or failed thermal overload relay heater elements',
        ],
        recommendedChecks: const [
          'Measure 3-phase current draw using clamp meter; verify < 5% unbalance',
          'Check motor winding resistance to ground using insulation tester',
          'Rotate pump shaft manually with power off to test for binding',
          'Inspect contactor contacts for pitting and carbon buildup',
        ],
        safetyNotes:
            'SAFETY FIRST: Discharge power-factor correction capacitors before servicing motor terminals. Confirm zero voltage with calibrated multimeter.',
        timestamp: DateTime.now(),
        source: 'Field Diagnostics Expert (Offline Engine)',
      );
    }

    // Default Generic Mechanical & Electrical Diagnostic
    return TroubleshootingAdvice(
      query: query,
      possibleCauses: const [
        'Intermittent sensor feedback or faulty potentiometer calibration',
        'Terminal block connection oxidation or loose control wiring',
        'Auxiliary safety interlock or limit switch open circuit',
        'Supply power voltage sagging below operating threshold',
      ],
      recommendedChecks: const [
        'Inspect primary electrical disconnect fuses and circuit breaker',
        'Check control circuit 24VAC / 24VDC transformer output voltage',
        'Verify integrity of all safety interlocks and emergency stop circuits',
        'Review manufacturer error codes on equipment control board',
      ],
      safetyNotes:
          'ATTENTION: Never bypass equipment safety switches during diagnosis. Adhere to site safety regulations and wear standard field PPE.',
      timestamp: DateTime.now(),
      source: 'Field Diagnostics Expert (Offline Engine)',
    );
  }
}

