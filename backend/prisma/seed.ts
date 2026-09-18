import { PrismaClient, Role, Priority, TaskStatus, PhotoType } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Starting FIELDFlow database seeding...');

  // 1. Clean existing records
  await prisma.notification.deleteMany({});
  await prisma.location.deleteMany({});
  await prisma.taskPhoto.deleteMany({});
  await prisma.taskNote.deleteMany({});
  await prisma.task.deleteMany({});
  await prisma.user.deleteMany({});

  const passwordHash = await bcrypt.hash('password123', 10);
  const adminPasswordHash = await bcrypt.hash('admin123', 10);

  // 2. Create Users
  const adminUser = await prisma.user.create({
    data: {
      name: 'System Administrator',
      email: 'admin@fieldflow.dev',
      passwordHash: adminPasswordHash,
      role: Role.ADMIN,
    },
  });

  const worker1 = await prisma.user.create({
    data: {
      name: 'Amrit Sharma',
      email: 'worker@example.com',
      passwordHash: passwordHash,
      role: Role.FIELD_WORKER,
    },
  });

  const worker2 = await prisma.user.create({
    data: {
      name: 'Elena Rostova',
      email: 'worker2@example.com',
      passwordHash: passwordHash,
      role: Role.FIELD_WORKER,
    },
  });

  console.log('✅ Created users:');
  console.log(`   - Admin: ${adminUser.email}`);
  console.log(`   - Field Worker 1: ${worker1.email} (Assigned primary tasks)`);
  console.log(`   - Field Worker 2: ${worker2.email}`);

  // 3. Create 22 Realistic Field Tasks
  const taskData = [
    {
      title: 'Commercial HVAC Airflow & Cooling Diagnostic',
      description: 'Customer reports 3rd floor rooftop chiller is running continuously but airflow is low and ambient temp exceeds 78°F. Check refrigerant pressure and filter plenum.',
      customerName: 'Apex Financial Center',
      customerPhone: '+1 (555) 234-5678',
      address: '742 Evergreen Terrace, Suite 300, Springfield, IL',
      latitude: 39.7817,
      longitude: -89.6501,
      priority: Priority.HIGH,
      status: TaskStatus.IN_PROGRESS,
      scheduledAt: new Date(Date.now() - 3600000 * 2), // 2 hours ago
      assignedToId: worker1.id,
      version: 1,
    },
    {
      title: 'Solar Photovoltaic Inverter Fault Code E-04',
      description: 'SolarEdge 10kW inverter trippped during peak solar hours. Investigate string voltage DC ground fault and test isolation resistance.',
      customerName: 'Summit Green Logistics',
      customerPhone: '+1 (555) 345-6789',
      address: '1200 Industrial Parkway, Dock 4, Columbus, OH',
      latitude: 39.9612,
      longitude: -82.9988,
      priority: Priority.URGENT,
      status: TaskStatus.ACCEPTED,
      scheduledAt: new Date(Date.now() + 3600000 * 1), // in 1 hour
      assignedToId: worker1.id,
      version: 1,
    },
    {
      title: 'Fiber Optic Distribution Hub Splicing & OTDR Test',
      description: 'New 48-strand fiber trunk installation requires fusion splicing at splice enclosure B-12 followed by bidirectional OTDR loss verification.',
      customerName: 'Metro Telecom Infrastructure',
      customerPhone: '+1 (555) 456-7890',
      address: '450 North Michigan Avenue, Chicago, IL',
      latitude: 41.8905,
      longitude: -87.6243,
      priority: Priority.MEDIUM,
      status: TaskStatus.ASSIGNED,
      scheduledAt: new Date(Date.now() + 3600000 * 4), // in 4 hours
      assignedToId: worker1.id,
      version: 1,
    },
    {
      title: 'Three-Phase Industrial Motor Starter Replacement',
      description: 'Replace worn contactor and thermal overload relay on 25HP water booster pump. Re-torque terminal lugs and test current draw under load.',
      customerName: 'Highland Municipal Water Works',
      customerPhone: '+1 (555) 567-8901',
      address: '88 Pump Station Road, Indianapolis, IN',
      latitude: 39.7684,
      longitude: -86.1581,
      priority: Priority.HIGH,
      status: TaskStatus.COMPLETED,
      scheduledAt: new Date(Date.now() - 3600000 * 24), // yesterday
      assignedToId: worker1.id,
      version: 2,
    },
    {
      title: 'Walk-In Freezer Compressor R-404A Leak Repair',
      description: 'Supermarket freezer temperature rose to 15°F. Detected micro-leak at suction service valve. Evacuate system, brazing repair, nitrogen pressure test, and recharge.',
      customerName: 'FreshFare Supermarkets',
      customerPhone: '+1 (555) 678-9012',
      address: '3200 West Broad Street, Richmond, VA',
      latitude: 37.5407,
      longitude: -77.436,
      priority: Priority.URGENT,
      status: TaskStatus.IN_PROGRESS,
      scheduledAt: new Date(Date.now() - 3600000 * 1),
      assignedToId: worker1.id,
      version: 1,
    },
    {
      title: 'Smart Electrical Submetering Panel Commissioning',
      description: 'Install 16 CT clamps inside tenant distribution panelboard. Verify Modbus TCP communication to central building management system.',
      customerName: 'Skyline Plaza Management',
      customerPhone: '+1 (555) 789-0123',
      address: '500 South Grand Avenue, Los Angeles, CA',
      latitude: 34.0522,
      longitude: -118.2437,
      priority: Priority.MEDIUM,
      status: TaskStatus.ASSIGNED,
      scheduledAt: new Date(Date.now() + 3600000 * 8),
      assignedToId: worker1.id,
      version: 1,
    },
    {
      title: 'Diesel Generator 500-Hour Preventive Maintenance',
      description: 'Caterpillar 350kW standby generator scheduled service. Replace engine oil, oil filter, fuel water separator, test block heater, and execute 15-minute transfer switch test.',
      customerName: 'St. Jude Community Hospital',
      customerPhone: '+1 (555) 890-1234',
      address: '262 Danny Thomas Place, Memphis, TN',
      latitude: 35.1495,
      longitude: -90.049,
      priority: Priority.HIGH,
      status: TaskStatus.ASSIGNED,
      scheduledAt: new Date(Date.now() + 3600000 * 26),
      assignedToId: worker1.id,
      version: 1,
    },
    {
      title: 'Hydraulic Freight Elevator Oil Pressure Fluctuations',
      description: 'Inspect hydraulic valve block seals and reservoir fluid levels. Replace worn spool seals causing uneven leveling at ground landing.',
      customerName: 'Pioneer Warehousing Depot',
      customerPhone: '+1 (555) 901-2345',
      address: '1500 Distribution Way, Dallas, TX',
      latitude: 32.7767,
      longitude: -96.797,
      priority: Priority.HIGH,
      status: TaskStatus.ASSIGNED,
      scheduledAt: new Date(Date.now() + 3600000 * 30),
      assignedToId: worker1.id,
      version: 1,
    },
    {
      title: 'Commercial Kitchen Fire Suppression Nozzle Inspection',
      description: 'Semiannual NFPA-96 inspection. Verify fusible link integrity, test pull station microswitch, blow nitrogen through discharge piping.',
      customerName: 'Bistro 44 Dining',
      customerPhone: '+1 (555) 012-3456',
      address: '44 Market Street, San Francisco, CA',
      latitude: 37.7937,
      longitude: -122.3965,
      priority: Priority.LOW,
      status: TaskStatus.ASSIGNED,
      scheduledAt: new Date(Date.now() + 3600000 * 48),
      assignedToId: worker1.id,
      version: 1,
    },
    {
      title: 'Enterprise Mesh Wi-Fi Access Point Site Survey',
      description: 'Perform RF spectrum analysis and calibrate 12 UniFi Wi-Fi 6 Enterprise APs across open-plan engineering floors.',
      customerName: 'Vanguard Software Labs',
      customerPhone: '+1 (555) 123-7890',
      address: '100 Innovation Drive, Austin, TX',
      latitude: 30.2672,
      longitude: -97.7431,
      priority: Priority.LOW,
      status: TaskStatus.COMPLETED,
      scheduledAt: new Date(Date.now() - 3600000 * 48),
      assignedToId: worker1.id,
      version: 2,
    },
    {
      title: 'EV Fast Charger (DCFC) Dispenser Screen Glitch',
      description: 'ABB Terra 184 DC Fast Charger touchscreen is unresponsive after firmware update. Perform hard reboot, reload configuration profile, test RFID swipe.',
      customerName: 'VoltCharge Public Station #8',
      customerPhone: '+1 (555) 234-8901',
      address: '890 Highway 101, San Jose, CA',
      latitude: 37.3382,
      longitude: -121.8863,
      priority: Priority.MEDIUM,
      status: TaskStatus.ASSIGNED,
      scheduledAt: new Date(Date.now() + 3600000 * 12),
      assignedToId: worker1.id,
      version: 1,
    },
    {
      title: 'Industrial Reverse Osmosis Membrane Cleaning',
      description: 'Clean RO train #2 with acid wash cycle to remove calcium carbonate scaling. Recheck permeate flow rate and conductivity readings.',
      customerName: 'Cascade Beverage Bottling',
      customerPhone: '+1 (555) 345-9012',
      address: '77 Brewery Creek Blvd, Portland, OR',
      latitude: 45.5152,
      longitude: -122.6784,
      priority: Priority.MEDIUM,
      status: TaskStatus.ACCEPTED,
      scheduledAt: new Date(Date.now() + 3600000 * 20),
      assignedToId: worker2.id,
      version: 1,
    },
    {
      title: 'Variable Air Volume (VAV) Damper Actuator Replacement',
      description: 'Zone 402 damper is stuck at 100% open, over-cooling conference rooms. Replace 24VAC Belimo actuator and verify potentiometer feedback.',
      customerName: 'Prism Tech Tower',
      customerPhone: '+1 (555) 456-0123',
      address: '1100 6th Ave, Seattle, WA',
      latitude: 47.6062,
      longitude: -122.3321,
      priority: Priority.HIGH,
      status: TaskStatus.ASSIGNED,
      scheduledAt: new Date(Date.now() + 3600000 * 14),
      assignedToId: worker2.id,
      version: 1,
    },
    {
      title: 'Cellular Base Station 48V Rectifier Battery Bank Test',
      description: 'Perform discharge load test on 4 strings of 2V VRLA battery cells. Identify failing cells and measure internal conductance.',
      customerName: 'TowerLink Wireless',
      customerPhone: '+1 (555) 567-1234',
      address: 'Tower Ridge Road, Site FL-402, Orlando, FL',
      latitude: 28.5383,
      longitude: -81.3792,
      priority: Priority.URGENT,
      status: TaskStatus.ASSIGNED,
      scheduledAt: new Date(Date.now() + 3600000 * 5),
      assignedToId: worker2.id,
      version: 1,
    },
    {
      title: 'Cleanroom Hepa Filter Certification & Velocity Profile',
      description: 'ISO Class 6 cleanroom annual aerosol photometer leak test. Record face velocity grid at 64 points across ceiling grid.',
      customerName: 'BioPharm Therapeutics Lab',
      customerPhone: '+1 (555) 678-2345',
      address: '200 Discovery Way, Cambridge, MA',
      latitude: 42.3736,
      longitude: -71.1097,
      priority: Priority.MEDIUM,
      status: TaskStatus.ASSIGNED,
      scheduledAt: new Date(Date.now() + 3600000 * 52),
      assignedToId: worker2.id,
      version: 1,
    },
    {
      title: 'Automatic Sliding Entrance Door Sensor Alignment',
      description: 'Main hospital lobby sliding door fails to reopen when obstructed. Re-align infrared motion curtain and test safety break-out switch.',
      customerName: 'Merit Health Hospital',
      customerPhone: '+1 (555) 789-3456',
      address: '400 Hospital Boulevard, Nashville, TN',
      latitude: 36.1627,
      longitude: -86.7816,
      priority: Priority.HIGH,
      status: TaskStatus.ACCEPTED,
      scheduledAt: new Date(Date.now() + 3600000 * 7),
      assignedToId: worker2.id,
      version: 1,
    },
    {
      title: 'Roof Heat Recovery Ventilator (HRV) Belt Tensioning',
      description: 'Routine quarterly inspection. Inspect drive belts for cracks, grease pillow block bearings, replace MERV 13 pre-filters.',
      customerName: 'Civic Center Library',
      customerPhone: '+1 (555) 890-4567',
      address: '100 Civic Plaza, Denver, CO',
      latitude: 39.7392,
      longitude: -104.9903,
      priority: Priority.LOW,
      status: TaskStatus.ASSIGNED,
      scheduledAt: new Date(Date.now() + 3600000 * 72),
      assignedToId: worker1.id,
      version: 1,
    },
    {
      title: 'Emergency Eye Wash & Deluge Shower Water Flow Calibration',
      description: 'ANSI Z358.1 weekly compliance flush and temperature recording (60-100°F tepid water threshold). Rebuild thermostatic mixing valve on unit #4.',
      customerName: 'Apex Chemical Refineries',
      customerPhone: '+1 (555) 901-5678',
      address: '500 Petrochemical Way, Houston, TX',
      latitude: 29.7604,
      longitude: -95.3698,
      priority: Priority.URGENT,
      status: TaskStatus.ASSIGNED,
      scheduledAt: new Date(Date.now() + 3600000 * 3),
      assignedToId: worker1.id,
      version: 1,
    },
    {
      title: 'Overhead Crane Pendant Cable & Limit Switch Check',
      description: '5-ton bridge crane hoist pendant cable showing outer sheath abrasion. Rewire pendant controller and calibrate upper hoist limit switch.',
      customerName: 'Midwest Steel Fabricators',
      customerPhone: '+1 (555) 012-6789',
      address: '2200 Ironworks Road, Gary, IN',
      latitude: 41.5934,
      longitude: -87.3464,
      priority: Priority.HIGH,
      status: TaskStatus.ASSIGNED,
      scheduledAt: new Date(Date.now() + 3600000 * 18),
      assignedToId: worker1.id,
      version: 1,
    },
    {
      title: 'Commercial Boiler Burner Combustion Efficiency Tune-up',
      description: 'Perform flue gas combustion analysis using test analyzer. Adjust fuel-air ratio linkage to achieve optimal O2 and CO2 levels.',
      customerName: 'Grandview Senior Living',
      customerPhone: '+1 (555) 123-8901',
      address: '710 Grandview Terrace, Minneapolis, MN',
      latitude: 44.9778,
      longitude: -93.265,
      priority: Priority.MEDIUM,
      status: TaskStatus.ASSIGNED,
      scheduledAt: new Date(Date.now() + 3600000 * 36),
      assignedToId: worker1.id,
      version: 1,
    },
    {
      title: 'Server Room CRAC Unit Condensate Pump Clog',
      description: 'High water alarm sounded in data center row 4. Clear algal slime build-up from condensate drain trap and test secondary float switch.',
      customerName: 'ColoRack Datacenters',
      customerPhone: '+1 (555) 234-9012',
      address: '800 Fiber Parkway, Ashburn, VA',
      latitude: 39.0438,
      longitude: -77.4874,
      priority: Priority.URGENT,
      status: TaskStatus.ASSIGNED,
      scheduledAt: new Date(Date.now() + 3600000 * 2),
      assignedToId: worker1.id,
      version: 1,
    },
    {
      title: 'Pneumatic Control Air Compressor Desiccant Replacement',
      description: 'Replace desiccant bead cartridges in twin-tower compressed air dryer supplying building HVAC pneumatic damper lines.',
      customerName: 'Heritage Court Building',
      customerPhone: '+1 (555) 345-0123',
      address: '330 Court Street, Boston, MA',
      latitude: 42.3601,
      longitude: -71.0589,
      priority: Priority.LOW,
      status: TaskStatus.ASSIGNED,
      scheduledAt: new Date(Date.now() + 3600000 * 60),
      assignedToId: worker1.id,
      version: 1,
    },
  ];

  for (const t of taskData) {
    const createdTask = await prisma.task.create({ data: t });

    // Add initial notes to in-progress or completed tasks
    if (createdTask.status === TaskStatus.IN_PROGRESS) {
      await prisma.taskNote.create({
        data: {
          taskId: createdTask.id,
          userId: worker1.id,
          content: 'Arrived on site at 09:15. Met with facility manager. Commenced initial diagnostics on unit.',
        },
      });

      await prisma.location.create({
        data: {
          taskId: createdTask.id,
          userId: worker1.id,
          latitude: createdTask.latitude,
          longitude: createdTask.longitude,
          accuracy: 4.5,
          timestamp: new Date(Date.now() - 3600000),
        },
      });
    }

    if (createdTask.status === TaskStatus.COMPLETED) {
      await prisma.taskNote.create({
        data: {
          taskId: createdTask.id,
          userId: worker1.id,
          content: 'Work completed according to OEM specifications. Measured voltage balance within 1.5%. Client sign-off obtained.',
        },
      });

      await prisma.taskPhoto.create({
        data: {
          taskId: createdTask.id,
          userId: worker1.id,
          url: 'https://images.unsplash.com/photo-1581092160607-ee22621dd758?w=800&auto=format&fit=crop&q=60',
          type: PhotoType.AFTER_SERVICE,
        },
      });
    }
  }

  console.log(`✅ Created ${taskData.length} realistic field tasks with notes and locations.`);

  // 4. Create Notifications for Field Worker
  await prisma.notification.createMany({
    data: [
      {
        userId: worker1.id,
        title: 'Emergency Job Dispatched',
        body: 'Walk-In Freezer Compressor R-404A Leak Repair has been assigned with URGENT priority.',
        type: 'TASK_ASSIGNED',
        read: false,
      },
      {
        userId: worker1.id,
        title: 'Schedule Reminder',
        body: 'You have 3 high priority tasks scheduled for today. Check your dashboard.',
        type: 'REMINDER',
        read: false,
      },
      {
        userId: worker1.id,
        title: 'System Synced',
        body: 'All your offline task submissions from yesterday were processed successfully.',
        type: 'SYSTEM',
        read: true,
      },
    ],
  });

  console.log('✅ Created initial worker notifications.');
  console.log('🎉 Database seeding complete!');
}

main()
  .catch((e) => {
    console.error('❌ Seeding error:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

