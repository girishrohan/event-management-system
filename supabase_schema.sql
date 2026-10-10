-- =========================================================================
-- AuraEvents Database Management System (DBMS) Schema
-- DBMS Practical College Mini-Project: ER Diagram Relational Mapping
-- CHAPTER 4 - CODING: 4.1 BACK END
-- Database: PostgreSQL (via Supabase / Local Sandbox)
-- =========================================================================

-- Enable secure cryptographic hashing extension
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- DROP EXISTING TABLES IF THEY EXIST (To prevent conflict during re-runs)
DROP TABLE IF EXISTS Payment CASCADE;
DROP TABLE IF EXISTS Booking CASCADE;
DROP TABLE IF EXISTS Participant CASCADE;
DROP TABLE IF EXISTS Event CASCADE;
DROP TABLE IF EXISTS inquiries CASCADE;
DROP TABLE IF EXISTS services CASCADE;
DROP TABLE IF EXISTS admins CASCADE;

-- CREATE services catalog table (for front-end catalog)
CREATE TABLE services (
    id VARCHAR(50) PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL,
    base_price NUMERIC(10, 2) NOT NULL,
    pricing_model VARCHAR(20) NOT NULL CHECK (pricing_model IN ('flat', 'per-guest')),
    description TEXT NOT NULL,
    icon_key VARCHAR(50) NOT NULL,
    is_standard BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- CREATE inquiries table
CREATE TABLE inquiries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rep_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL,
    specs_notes TEXT NOT NULL,
    status VARCHAR(50) DEFAULT 'Applied' NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- CREATE admins table (Secure Admin Accounts)
CREATE TABLE admins (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone_number VARCHAR(20) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- EVENT TABLE
CREATE TABLE Event (
    EventID SERIAL PRIMARY KEY,
    EventName VARCHAR(100) NOT NULL,
    EventDate DATE NOT NULL,
    Location VARCHAR(150) NOT NULL,
    Capacity INTEGER NOT NULL,
    TicketPrice DECIMAL(10,2) NOT NULL
);

-- PARTICIPANT TABLE
CREATE TABLE Participant (
    ParticipantID SERIAL PRIMARY KEY,
    FirstName VARCHAR(100) NOT NULL,
    LastName VARCHAR(100) NOT NULL,
    Email VARCHAR(150) UNIQUE NOT NULL,
    Phone VARCHAR(15),
    Address TEXT
);

-- BOOKING TABLE
CREATE TABLE Booking (
    BookingID SERIAL PRIMARY KEY,
    EventID INTEGER NOT NULL,
    ParticipantID INTEGER NOT NULL,
    BookingDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    BookingStatus VARCHAR(20) DEFAULT 'Confirmed',
    TotalAmount DECIMAL(10,2),
    CONSTRAINT fk_booking_event FOREIGN KEY (EventID) REFERENCES Event(EventID) ON DELETE CASCADE,
    CONSTRAINT fk_booking_participant FOREIGN KEY (ParticipantID) REFERENCES Participant(ParticipantID) ON DELETE CASCADE
);

-- PAYMENT TABLE
CREATE TABLE Payment (
    PaymentID SERIAL PRIMARY KEY,
    BookingID INTEGER NOT NULL,
    Amount DECIMAL(10,2) NOT NULL,
    PaymentStatus VARCHAR(20) DEFAULT 'Paid',
    CONSTRAINT fk_payment_booking FOREIGN KEY (BookingID) REFERENCES Booking(BookingID) ON DELETE CASCADE
);

-- =========================================================================
-- DATABASE TRIGGERS (Calculates derived TotalAmount column automatically)
-- =========================================================================

CREATE OR REPLACE FUNCTION calculate_booking_total()
RETURNS TRIGGER AS $$
DECLARE
    v_price DECIMAL(10, 2);
BEGIN
    -- Query ticket price from referenced Event table
    SELECT TicketPrice INTO v_price 
    FROM Event 
    WHERE EventID = NEW.EventID;
    
    -- Calculate derived TotalAmount
    NEW.TotalAmount := COALESCE(v_price, 0.00);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_calculate_booking_total
BEFORE INSERT OR UPDATE ON Booking
FOR EACH ROW
EXECUTE FUNCTION calculate_booking_total();

-- =========================================================================
-- DML DATA SEEDING (Populate initial normalized records)
-- =========================================================================

-- Seed 18 services
INSERT INTO services (id, title, category, base_price, pricing_model, description, icon_key, is_standard) VALUES
('infra', 'Venue Tents & Setup', 'Infrastructure', 1200.00, 'flat', 'Strong weather-proof tents, tables, chairs, and fencing for your event ground.', 'Infrastructure', TRUE),
('speakers', 'Stage Speakers & Sound', 'AV & Sound', 850.00, 'flat', 'High-quality speakers, amplifiers, and sound controllers to play clear audio.', 'Audio', TRUE),
('projectors', 'HD Projectors & Visuals', 'AV & Sound', 500.00, 'flat', 'Bright visual projectors and wide screens to show videos or presentations.', 'Visual', TRUE),
('catering', 'Food & Catering', 'Food & Talent', 12.00, 'per-guest', 'Tasty food and drinks, live cooking counters, and uniform buffet servers.', 'Dining', FALSE),
('photos', 'Photos & Video Shoots', 'AV & Sound', 950.00, 'flat', 'Professional camera team, candid photos, and high-quality event videos.', 'Media', FALSE),
('stage', 'Custom Stage Design', 'Infrastructure', 1500.00, 'flat', 'Beautifully decorated wooden stages, background themes, and red carpets.', 'Stage', FALSE),
('security', 'Security & Guard Crews', 'Logistics & Tech', 600.00, 'flat', 'Trained guards, entrance metal detectors, and safe emergency exit planning.', 'Security', FALSE),
('drones', 'Drone Video & Live Stream', 'AV & Sound', 750.00, 'flat', 'Flying cameras for sky views and live video broadcasting on YouTube.', 'Drone', FALSE),
('lights', 'Stage Lights & Lasers', 'AV & Sound', 1100.00, 'flat', 'Colorful moving lights, stage spotlights, and smoke effects.', 'Lighting', FALSE),
('artist', 'Celebrity & Band Bookings', 'Food & Talent', 3000.00, 'flat', 'Hiring famous singers, music bands, or DJs for guest entertainment.', 'Talent', FALSE),
('rsvp', 'Invitation & Guest Invites', 'Logistics & Tech', 350.00, 'flat', 'Beautiful digital cards sent on WhatsApp and phone support for guest confirmations.', 'Invites', FALSE),
('valet', 'Valet Parking & Shuttles', 'Logistics & Tech', 450.00, 'flat', 'Trained drivers to park cars and golf carts for elderly guests.', 'Logistics', FALSE),
('vr', 'Virtual Reality Game Zones', 'Logistics & Tech', 800.00, 'flat', 'Fun VR headset game areas and a rotating selfie camera booth.', 'VR', FALSE),
('cleanup', 'Eco-Friendly Cleaning', 'Infrastructure', 2.00, 'per-guest', 'Garbage recycling bins and cleanup staff to keep the ground clean.', 'Cleanup', FALSE),
('ticketing', 'Digital Entry Tickets', 'Logistics & Tech', 4.00, 'per-guest', 'Wristband entries, high-speed gate scanners, and physical receipt printers.', 'Ticketing', FALSE),
('emcee', 'Event Host & Speaker', 'Food & Talent', 500.00, 'flat', 'Friendly anchors and hosts to introduce events and play games with guests.', 'Talent', FALSE),
('soundproof', 'Sound Isolation Setup', 'Infrastructure', 900.00, 'flat', 'Sound-dampening panels and blankets to block external noises.', 'Acoustics', FALSE),
('pyrotechnics', 'Special Effects & Sparklers', 'AV & Sound', 650.00, 'flat', 'Safe cold sparks, stage bubble machines, and paper confetti blasts.', 'Pyrotechnics', FALSE);

-- Seed Events
INSERT INTO Event (EventName, EventDate, Location, Capacity, TicketPrice) VALUES 
('Tech Conference 2026', '2026-07-15', 'Bangalore', 500, 1000.00),
('Cultural Fest 2026', '2026-08-10', 'Mysore', 300, 500.00),
('Coding Workshop', '2026-06-20', 'Bangalore', 150, 750.00),
('Startup Expo', '2026-09-12', 'Hubli', 400, 1200.00),
('AI Summit', '2026-10-05', 'Bangalore', 600, 1500.00);

-- Verify Event insertions
-- SELECT * FROM Event;

-- Seed Participants
INSERT INTO Participant (FirstName, LastName, Email, Phone, Address) VALUES 
('Rahul','Sharma','rahul@gmail.com','9876543210','Bangalore'),
('Priya','Nair','priya@gmail.com','9123456789','Mysore'),
('Arjun','Kumar','arjun@gmail.com','9988776655','Tumkur'),
('Sneha','Patel','sneha@gmail.com','9871234567','Hubli'),
('Amit','Verma','amit@gmail.com','9988445522','Belgaum');

-- Verify Participant insertions
-- SELECT * FROM Participant;

-- Seed Bookings
INSERT INTO Booking (EventID, ParticipantID, BookingDate, BookingStatus, TotalAmount) VALUES 
(1, 1, CURRENT_TIMESTAMP, 'Confirmed', 1000.00),
(2, 2, CURRENT_TIMESTAMP, 'Confirmed', 500.00),
(3, 3, CURRENT_TIMESTAMP, 'Pending', 750.00),
(4, 4, CURRENT_TIMESTAMP, 'Confirmed', 1200.00),
(5, 5, CURRENT_TIMESTAMP, 'Confirmed', 1500.00);

-- Verify Booking insertions
-- SELECT * FROM Booking;

-- Seed Payments
INSERT INTO Payment (BookingID, Amount, PaymentStatus) VALUES 
(1, 1000.00, 'Paid'),
(2, 500.00, 'Paid'),
(3, 750.00, 'Pending'),
(4, 1200.00, 'Paid'),
(5, 1500.00, 'Paid');

-- Seed Inquiries
INSERT INTO inquiries (rep_name, email, specs_notes, status) VALUES 
('Event Chair Mark', 'mark.chair@fests.org', 'Requesting custom quote for stadium sports concert setup. Need sound arrays and RFID entry portals.', 'Received'),
('Sneha Patel', 'sneha@student.edu', 'Requesting sound barrier length details and 500W speaker layouts for the outdoor lawn party.', 'Approved'),
('Aditya Rao', 'aditya@corporate.com', 'Corporate summit staging request. Needs standard catering for 250 guests and modern audio setup.', 'Under Review');

-- Verify Payment insertions
-- SELECT * FROM Payment;

-- Verify relationships: event bookings and payments
-- SELECT B.BookingID, P.FirstName, P.LastName, E.EventName, B.BookingStatus
-- FROM Booking B
-- JOIN Participant P ON B.ParticipantID = P.ParticipantID
-- JOIN Event E ON B.EventID = E.EventID;

-- SELECT P.PaymentID, E.EventName, PT.FirstName, P.Amount, P.PaymentStatus
-- FROM Payment P
-- JOIN Booking B ON P.BookingID = B.BookingID
-- JOIN Event E ON B.EventID = E.EventID
-- JOIN Participant PT ON B.ParticipantID = PT.ParticipantID;

-- Seed default admin with blowfish hash
INSERT INTO admins (name, email, phone_number, password_hash)
VALUES (
    'System Admin',
    'dd058288@gmail.com',
    '6363579209',
    crypt('Deeku@9686', gen_salt('bf'))
) ON CONFLICT (email) DO NOTHING;

-- RPC secure authentication function
CREATE OR REPLACE FUNCTION verify_admin_login(
    p_email TEXT,
    p_phone TEXT,
    p_password TEXT
)
RETURNS TABLE (
    id UUID,
    name VARCHAR,
    email VARCHAR,
    phone_number VARCHAR
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT a.id, a.name, a.email, a.phone_number
    FROM admins a
    WHERE a.email = p_email 
      AND a.phone_number = p_phone
      AND a.password_hash = crypt(p_password, a.password_hash);
END;
$$;

-- =========================================================================
-- DATABASE ACCESS CONTROLS (Row Level Security - RLS Policies)
-- Configure tables to permit secure public CRUD operations for front-end demo
-- =========================================================================

ALTER TABLE services ENABLE ROW LEVEL SECURITY;
ALTER TABLE Event ENABLE ROW LEVEL SECURITY;
ALTER TABLE Participant ENABLE ROW LEVEL SECURITY;
ALTER TABLE Payment ENABLE ROW LEVEL SECURITY;
ALTER TABLE Booking ENABLE ROW LEVEL SECURITY;
ALTER TABLE inquiries ENABLE ROW LEVEL SECURITY;
ALTER TABLE admins ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Enable read access for all on services" ON services FOR SELECT USING (true);
CREATE POLICY "Enable read access for all on Event" ON Event FOR SELECT USING (true);
CREATE POLICY "Enable insert access for all on Event" ON Event FOR INSERT WITH CHECK (true);

CREATE POLICY "Enable select access for all on Participant" ON Participant FOR SELECT USING (true);
CREATE POLICY "Enable insert access for all on Participant" ON Participant FOR INSERT WITH CHECK (true);

CREATE POLICY "Enable select access for all on Payment" ON Payment FOR SELECT USING (true);
CREATE POLICY "Enable insert access for all on Payment" ON Payment FOR INSERT WITH CHECK (true);

CREATE POLICY "Enable select access for all on Booking" ON Booking FOR SELECT USING (true);
CREATE POLICY "Enable insert access for all on Booking" ON Booking FOR INSERT WITH CHECK (true);
CREATE POLICY "Enable update access for all on Booking" ON Booking FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY "Enable delete access for all on Booking" ON Booking FOR DELETE USING (true);

CREATE POLICY "Enable insert access for all on inquiries" ON inquiries FOR INSERT WITH CHECK (true);
CREATE POLICY "Enable select access for all on inquiries" ON inquiries FOR SELECT USING (true);
CREATE POLICY "Enable update access for all on inquiries" ON inquiries FOR UPDATE USING (true) WITH CHECK (true);
