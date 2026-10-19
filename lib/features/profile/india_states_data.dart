/// Vedic ephemeris geography — the Dart port of the web app's
/// `INDIAN_STATES_DATA` (`frontend/src/utils/vedicAstrology.js` lines 120-575).
///
/// Every state/union territory and every city keeps the exact `lat`/`lon` the
/// web dashboard uses to auto-fill the "Geographic & Vedic Ephemeris
/// Coordinates" panel, so the customer app resolves identical coordinates for
/// the same birth place.
class CityCoords {
  const CityCoords({required this.name, required this.lat, required this.lon});

  final String name;
  final double lat;
  final double lon;
}

class IndiaStateData {
  const IndiaStateData({
    required this.capital,
    required this.lat,
    required this.lon,
    required this.cities,
  });

  final String capital;
  final double lat;
  final double lon;
  final List<CityCoords> cities;
}

class IndiaStatesData {
  IndiaStatesData._();

  /// All 33 states/UTs keyed exactly as the web `<select>` renders them.
  static const Map<String, IndiaStateData> states = {
    'Andhra Pradesh': IndiaStateData(
      capital: 'Vijayawada',
      lat: 16.5062,
      lon: 80.6480,
      cities: [
        CityCoords(name: 'Vijayawada', lat: 16.5062, lon: 80.6480),
        CityCoords(name: 'Visakhapatnam', lat: 17.6868, lon: 83.2185),
        CityCoords(name: 'Tirupati', lat: 13.6288, lon: 79.4192),
        CityCoords(name: 'Guntur', lat: 16.3067, lon: 80.4365),
        CityCoords(name: 'Rajahmundry', lat: 16.9891, lon: 81.7799),
        CityCoords(name: 'Kakinada', lat: 16.9891, lon: 82.2475),
        CityCoords(name: 'Nellore', lat: 14.4426, lon: 79.9865),
        CityCoords(name: 'Kurnool', lat: 15.8281, lon: 78.0373),
        CityCoords(name: 'Kadapa', lat: 14.4673, lon: 78.8242),
        CityCoords(name: 'Anantapur', lat: 14.6819, lon: 77.6006),
        CityCoords(name: 'Eluru', lat: 16.7107, lon: 81.0952),
        CityCoords(name: 'Ongole', lat: 15.5057, lon: 80.0499),
        CityCoords(name: 'Srikakulam', lat: 18.2969, lon: 83.8968),
        CityCoords(name: 'Machilipatnam', lat: 16.1875, lon: 81.1389),
        CityCoords(name: 'Chittoor', lat: 13.2172, lon: 79.1003),
        CityCoords(name: 'Vizianagaram', lat: 18.1067, lon: 83.3956),
        CityCoords(name: 'Bhimavaram', lat: 16.5449, lon: 81.5212),
        CityCoords(name: 'Tenali', lat: 16.2435, lon: 80.6400),
        CityCoords(name: 'Nandyal', lat: 15.4884, lon: 78.4836),
        CityCoords(name: 'Hindupur', lat: 13.8290, lon: 77.4919),
      ],
    ),
    'Telangana': IndiaStateData(
      capital: 'Hyderabad',
      lat: 17.3850,
      lon: 78.4867,
      cities: [
        CityCoords(name: 'Hyderabad', lat: 17.3850, lon: 78.4867),
        CityCoords(name: 'Secunderabad', lat: 17.4399, lon: 78.4983),
        CityCoords(name: 'Warangal', lat: 17.9689, lon: 79.5941),
        CityCoords(name: 'Nizamabad', lat: 18.6725, lon: 78.0941),
        CityCoords(name: 'Karimnagar', lat: 18.4386, lon: 79.1288),
        CityCoords(name: 'Khammam', lat: 17.2473, lon: 80.1514),
        CityCoords(name: 'Ramagundam', lat: 18.7557, lon: 79.5126),
        CityCoords(name: 'Mahbubnagar', lat: 16.7488, lon: 77.9845),
        CityCoords(name: 'Nalgonda', lat: 17.0575, lon: 79.2684),
        CityCoords(name: 'Adilabad', lat: 19.6641, lon: 78.5320),
        CityCoords(name: 'Siddipet', lat: 18.1018, lon: 78.8520),
        CityCoords(name: 'Suryapet', lat: 17.1439, lon: 79.6239),
        CityCoords(name: 'Miryalaguda', lat: 16.8732, lon: 79.5647),
        CityCoords(name: 'Jagtial', lat: 18.7950, lon: 78.9128),
      ],
    ),
    'Karnataka': IndiaStateData(
      capital: 'Bengaluru',
      lat: 12.9716,
      lon: 77.5946,
      cities: [
        CityCoords(name: 'Bengaluru', lat: 12.9716, lon: 77.5946),
        CityCoords(name: 'Mysuru', lat: 12.2958, lon: 76.6394),
        CityCoords(name: 'Hubballi', lat: 15.3647, lon: 75.1240),
        CityCoords(name: 'Mangaluru', lat: 12.9141, lon: 74.8560),
        CityCoords(name: 'Belagavi', lat: 15.8497, lon: 74.4977),
        CityCoords(name: 'Davanagere', lat: 14.4644, lon: 75.9218),
        CityCoords(name: 'Ballari', lat: 15.1394, lon: 76.9214),
        CityCoords(name: 'Vijayapura', lat: 16.8302, lon: 75.7100),
        CityCoords(name: 'Shivamogga', lat: 13.9299, lon: 75.5681),
        CityCoords(name: 'Tumakuru', lat: 13.3379, lon: 77.1010),
        CityCoords(name: 'Udupi', lat: 13.3409, lon: 74.7421),
        CityCoords(name: 'Kalaburagi', lat: 17.3297, lon: 76.8343),
        CityCoords(name: 'Hassan', lat: 13.0033, lon: 76.1004),
        CityCoords(name: 'Bidar', lat: 17.9104, lon: 77.5199),
      ],
    ),
    'Tamil Nadu': IndiaStateData(
      capital: 'Chennai',
      lat: 13.0827,
      lon: 80.2707,
      cities: [
        CityCoords(name: 'Chennai', lat: 13.0827, lon: 80.2707),
        CityCoords(name: 'Coimbatore', lat: 11.0168, lon: 76.9558),
        CityCoords(name: 'Madurai', lat: 9.9252, lon: 78.1198),
        CityCoords(name: 'Tiruchirappalli', lat: 10.7905, lon: 78.7047),
        CityCoords(name: 'Salem', lat: 11.6643, lon: 78.1460),
        CityCoords(name: 'Tirunelveli', lat: 8.7139, lon: 77.7567),
        CityCoords(name: 'Erode', lat: 11.3410, lon: 77.7172),
        CityCoords(name: 'Vellore', lat: 12.9165, lon: 79.1325),
        CityCoords(name: 'Thanjavur', lat: 10.7870, lon: 79.1378),
        CityCoords(name: 'Kanchipuram', lat: 12.8342, lon: 79.7036),
        CityCoords(name: 'Tiruppur', lat: 11.1085, lon: 77.3411),
        CityCoords(name: 'Dindigul', lat: 10.3673, lon: 77.9803),
        CityCoords(name: 'Kumbakonam', lat: 10.9602, lon: 79.3845),
        CityCoords(name: 'Nagercoil', lat: 8.1833, lon: 77.4119),
        CityCoords(name: 'Hosur', lat: 12.7409, lon: 77.8253),
      ],
    ),
    'Maharashtra': IndiaStateData(
      capital: 'Mumbai',
      lat: 19.0760,
      lon: 72.8777,
      cities: [
        CityCoords(name: 'Mumbai', lat: 19.0760, lon: 72.8777),
        CityCoords(name: 'Pune', lat: 18.5204, lon: 73.8567),
        CityCoords(name: 'Nagpur', lat: 21.1458, lon: 79.0882),
        CityCoords(name: 'Nashik', lat: 19.9975, lon: 73.7898),
        CityCoords(name: 'Thane', lat: 19.2183, lon: 72.9781),
        CityCoords(
          name: 'Chhatrapati Sambhajinagar',
          lat: 19.8762,
          lon: 75.3433,
        ),
        CityCoords(name: 'Solapur', lat: 17.6599, lon: 75.9064),
        CityCoords(name: 'Kolhapur', lat: 16.7050, lon: 74.2433),
        CityCoords(name: 'Amravati', lat: 20.9320, lon: 77.7523),
        CityCoords(name: 'Navi Mumbai', lat: 19.0330, lon: 73.0297),
        CityCoords(name: 'Sangli', lat: 16.8524, lon: 74.5815),
        CityCoords(name: 'Jalgaon', lat: 21.0077, lon: 75.5626),
        CityCoords(name: 'Akola', lat: 20.7002, lon: 77.0082),
        CityCoords(name: 'Latur', lat: 18.4088, lon: 76.5604),
        CityCoords(name: 'Shirdi', lat: 19.7667, lon: 74.4767),
      ],
    ),
    'Gujarat': IndiaStateData(
      capital: 'Gandhinagar',
      lat: 23.2156,
      lon: 72.6369,
      cities: [
        CityCoords(name: 'Ahmedabad', lat: 23.0225, lon: 72.5714),
        CityCoords(name: 'Surat', lat: 21.1702, lon: 72.8311),
        CityCoords(name: 'Vadodara', lat: 22.3072, lon: 73.1812),
        CityCoords(name: 'Rajkot', lat: 22.3039, lon: 70.8022),
        CityCoords(name: 'Bhavnagar', lat: 21.7645, lon: 72.1519),
        CityCoords(name: 'Jamnagar', lat: 22.4707, lon: 70.0577),
        CityCoords(name: 'Gandhinagar', lat: 23.2156, lon: 72.6369),
        CityCoords(name: 'Junagadh', lat: 21.5222, lon: 70.4579),
        CityCoords(name: 'Anand', lat: 22.5645, lon: 72.9289),
        CityCoords(name: 'Navsari', lat: 20.9500, lon: 72.9300),
        CityCoords(name: 'Morbi', lat: 22.8120, lon: 70.8380),
        CityCoords(name: 'Dwarka', lat: 22.2442, lon: 68.9685),
        CityCoords(name: 'Somnath', lat: 20.8880, lon: 70.4010),
      ],
    ),
    'Uttar Pradesh': IndiaStateData(
      capital: 'Lucknow',
      lat: 26.8467,
      lon: 80.9462,
      cities: [
        CityCoords(name: 'Lucknow', lat: 26.8467, lon: 80.9462),
        CityCoords(name: 'Varanasi', lat: 25.3176, lon: 82.9739),
        CityCoords(name: 'Prayagraj', lat: 25.4358, lon: 81.8463),
        CityCoords(name: 'Kanpur', lat: 26.4499, lon: 80.3319),
        CityCoords(name: 'Agra', lat: 27.1767, lon: 78.0081),
        CityCoords(name: 'Noida', lat: 28.5355, lon: 77.3910),
        CityCoords(name: 'Greater Noida', lat: 28.4744, lon: 77.5040),
        CityCoords(name: 'Ghaziabad', lat: 28.6692, lon: 77.4538),
        CityCoords(name: 'Meerut', lat: 28.9845, lon: 77.7064),
        CityCoords(name: 'Ayodhya', lat: 26.7922, lon: 82.1998),
        CityCoords(name: 'Mathura', lat: 27.4924, lon: 77.6737),
        CityCoords(name: 'Vrindavan', lat: 27.5806, lon: 77.7006),
        CityCoords(name: 'Gorakhpur', lat: 26.7606, lon: 83.3732),
        CityCoords(name: 'Bareilly', lat: 28.3670, lon: 79.4304),
        CityCoords(name: 'Aligarh', lat: 27.8974, lon: 78.0880),
        CityCoords(name: 'Jhansi', lat: 25.4484, lon: 78.5685),
      ],
    ),
    'Delhi NCR': IndiaStateData(
      capital: 'New Delhi',
      lat: 28.6139,
      lon: 77.2090,
      cities: [
        CityCoords(name: 'New Delhi', lat: 28.6139, lon: 77.2090),
        CityCoords(name: 'Delhi', lat: 28.6139, lon: 77.2090),
        CityCoords(name: 'Gurugram', lat: 28.4595, lon: 77.0266),
        CityCoords(name: 'Noida', lat: 28.5355, lon: 77.3910),
        CityCoords(name: 'Faridabad', lat: 28.4089, lon: 77.3178),
        CityCoords(name: 'Ghaziabad', lat: 28.6692, lon: 77.4538),
      ],
    ),
    'Kerala': IndiaStateData(
      capital: 'Thiruvananthapuram',
      lat: 8.5241,
      lon: 76.9366,
      cities: [
        CityCoords(name: 'Thiruvananthapuram', lat: 8.5241, lon: 76.9366),
        CityCoords(name: 'Kochi', lat: 9.9312, lon: 76.2673),
        CityCoords(name: 'Kozhikode', lat: 11.2588, lon: 75.7804),
        CityCoords(name: 'Thrissur', lat: 10.5276, lon: 76.2144),
        CityCoords(name: 'Kollam', lat: 8.8932, lon: 76.6141),
        CityCoords(name: 'Palakkad', lat: 10.7867, lon: 76.6548),
        CityCoords(name: 'Alappuzha', lat: 9.4981, lon: 76.3388),
        CityCoords(name: 'Kannur', lat: 11.8745, lon: 75.3704),
        CityCoords(name: 'Kottayam', lat: 9.5916, lon: 76.5222),
        CityCoords(name: 'Guruvayur', lat: 10.5946, lon: 76.0416),
      ],
    ),
    'West Bengal': IndiaStateData(
      capital: 'Kolkata',
      lat: 22.5726,
      lon: 88.3639,
      cities: [
        CityCoords(name: 'Kolkata', lat: 22.5726, lon: 88.3639),
        CityCoords(name: 'Howrah', lat: 22.5958, lon: 88.2636),
        CityCoords(name: 'Durgapur', lat: 23.5204, lon: 87.3119),
        CityCoords(name: 'Asansol', lat: 23.6739, lon: 86.9524),
        CityCoords(name: 'Siliguri', lat: 26.7271, lon: 88.3953),
        CityCoords(name: 'Darjeeling', lat: 27.0410, lon: 88.2663),
        CityCoords(name: 'Kharagpur', lat: 22.3460, lon: 87.2320),
      ],
    ),
    'Rajasthan': IndiaStateData(
      capital: 'Jaipur',
      lat: 26.9124,
      lon: 75.7873,
      cities: [
        CityCoords(name: 'Jaipur', lat: 26.9124, lon: 75.7873),
        CityCoords(name: 'Jodhpur', lat: 26.2389, lon: 73.0243),
        CityCoords(name: 'Udaipur', lat: 24.5854, lon: 73.7125),
        CityCoords(name: 'Kota', lat: 25.2138, lon: 75.8648),
        CityCoords(name: 'Bikaner', lat: 28.0229, lon: 73.3119),
        CityCoords(name: 'Ajmer', lat: 26.4499, lon: 74.6399),
        CityCoords(name: 'Pushkar', lat: 26.4897, lon: 74.5511),
        CityCoords(name: 'Alwar', lat: 27.5530, lon: 76.6346),
      ],
    ),
    'Madhya Pradesh': IndiaStateData(
      capital: 'Bhopal',
      lat: 23.2599,
      lon: 77.4126,
      cities: [
        CityCoords(name: 'Bhopal', lat: 23.2599, lon: 77.4126),
        CityCoords(name: 'Indore', lat: 22.7196, lon: 75.8577),
        CityCoords(name: 'Jabalpur', lat: 23.1815, lon: 79.9864),
        CityCoords(name: 'Gwalior', lat: 26.2183, lon: 78.1828),
        CityCoords(name: 'Ujjain', lat: 23.1765, lon: 75.7885),
        CityCoords(name: 'Sagar', lat: 23.8388, lon: 78.7378),
        CityCoords(name: 'Satna', lat: 24.6005, lon: 80.8322),
        CityCoords(name: 'Rewa', lat: 24.5362, lon: 81.3037),
      ],
    ),
    'Bihar': IndiaStateData(
      capital: 'Patna',
      lat: 25.5941,
      lon: 85.1376,
      cities: [
        CityCoords(name: 'Patna', lat: 25.5941, lon: 85.1376),
        CityCoords(name: 'Gaya', lat: 24.7914, lon: 85.0002),
        CityCoords(name: 'Bhagalpur', lat: 25.2425, lon: 86.9842),
        CityCoords(name: 'Muzaffarpur', lat: 26.1209, lon: 85.3647),
        CityCoords(name: 'Darbhanga', lat: 26.1542, lon: 85.8918),
        CityCoords(name: 'Purnia', lat: 25.7771, lon: 87.4753),
      ],
    ),
    'Odisha': IndiaStateData(
      capital: 'Bhubaneswar',
      lat: 20.2961,
      lon: 85.8245,
      cities: [
        CityCoords(name: 'Bhubaneswar', lat: 20.2961, lon: 85.8245),
        CityCoords(name: 'Cuttack', lat: 20.4625, lon: 85.8828),
        CityCoords(name: 'Puri', lat: 19.8135, lon: 85.8312),
        CityCoords(name: 'Rourkela', lat: 22.2604, lon: 84.8536),
        CityCoords(name: 'Berhampur', lat: 19.3149, lon: 84.7941),
        CityCoords(name: 'Sambalpur', lat: 21.4669, lon: 83.9812),
      ],
    ),
    'Punjab': IndiaStateData(
      capital: 'Chandigarh',
      lat: 30.7333,
      lon: 76.7794,
      cities: [
        CityCoords(name: 'Chandigarh', lat: 30.7333, lon: 76.7794),
        CityCoords(name: 'Amritsar', lat: 31.6340, lon: 74.8723),
        CityCoords(name: 'Ludhiana', lat: 30.9010, lon: 75.8573),
        CityCoords(name: 'Jalandhar', lat: 31.3260, lon: 75.5762),
        CityCoords(name: 'Patiala', lat: 30.3398, lon: 76.3869),
        CityCoords(name: 'Bathinda', lat: 30.2110, lon: 74.9455),
        CityCoords(name: 'Mohali', lat: 30.7046, lon: 76.7179),
      ],
    ),
    'Haryana': IndiaStateData(
      capital: 'Chandigarh',
      lat: 30.7333,
      lon: 76.7794,
      cities: [
        CityCoords(name: 'Gurugram', lat: 28.4595, lon: 77.0266),
        CityCoords(name: 'Faridabad', lat: 28.4089, lon: 77.3178),
        CityCoords(name: 'Panipat', lat: 29.3909, lon: 76.9635),
        CityCoords(name: 'Ambala', lat: 30.3782, lon: 76.7767),
        CityCoords(name: 'Hisar', lat: 29.1492, lon: 75.7217),
        CityCoords(name: 'Karnal', lat: 29.6857, lon: 76.9905),
        CityCoords(name: 'Rohtak', lat: 28.8955, lon: 76.6066),
        CityCoords(name: 'Sonipat', lat: 28.9931, lon: 77.0151),
        CityCoords(name: 'Panchkula', lat: 30.6942, lon: 76.8606),
      ],
    ),
    'Uttarakhand': IndiaStateData(
      capital: 'Dehradun',
      lat: 30.3165,
      lon: 78.0322,
      cities: [
        CityCoords(name: 'Dehradun', lat: 30.3165, lon: 78.0322),
        CityCoords(name: 'Haridwar', lat: 29.9457, lon: 78.1642),
        CityCoords(name: 'Rishikesh', lat: 30.0869, lon: 78.2676),
        CityCoords(name: 'Roorkee', lat: 29.8543, lon: 77.8880),
        CityCoords(name: 'Haldwani', lat: 29.2183, lon: 79.5130),
        CityCoords(name: 'Nainital', lat: 29.3919, lon: 79.4542),
      ],
    ),
    'Goa': IndiaStateData(
      capital: 'Panaji',
      lat: 15.4909,
      lon: 73.8278,
      cities: [
        CityCoords(name: 'Panaji', lat: 15.4909, lon: 73.8278),
        CityCoords(name: 'Margao', lat: 15.2832, lon: 73.9862),
        CityCoords(name: 'Vasco da Gama', lat: 15.3982, lon: 73.8113),
        CityCoords(name: 'Mapusa', lat: 15.5937, lon: 73.8142),
      ],
    ),
    'Assam': IndiaStateData(
      capital: 'Guwahati',
      lat: 26.1445,
      lon: 91.7362,
      cities: [
        CityCoords(name: 'Guwahati', lat: 26.1445, lon: 91.7362),
        CityCoords(name: 'Silchar', lat: 24.8333, lon: 92.7789),
        CityCoords(name: 'Dibrugarh', lat: 27.4728, lon: 94.9120),
        CityCoords(name: 'Jorhat', lat: 26.7509, lon: 94.2037),
      ],
    ),
    'Jharkhand': IndiaStateData(
      capital: 'Ranchi',
      lat: 23.3441,
      lon: 85.3096,
      cities: [
        CityCoords(name: 'Ranchi', lat: 23.3441, lon: 85.3096),
        CityCoords(name: 'Jamshedpur', lat: 22.8046, lon: 86.2029),
        CityCoords(name: 'Dhanbad', lat: 23.7957, lon: 86.4304),
        CityCoords(name: 'Bokaro', lat: 23.6693, lon: 86.1511),
        CityCoords(name: 'Deoghar', lat: 24.4826, lon: 86.7001),
      ],
    ),
    'Chhattisgarh': IndiaStateData(
      capital: 'Raipur',
      lat: 21.2514,
      lon: 81.6296,
      cities: [
        CityCoords(name: 'Raipur', lat: 21.2514, lon: 81.6296),
        CityCoords(name: 'Bhilai', lat: 21.1938, lon: 81.3509),
        CityCoords(name: 'Bilaspur', lat: 22.0797, lon: 82.1409),
        CityCoords(name: 'Korba', lat: 22.3595, lon: 82.7501),
      ],
    ),
    'Himachal Pradesh': IndiaStateData(
      capital: 'Shimla',
      lat: 31.1048,
      lon: 77.1734,
      cities: [
        CityCoords(name: 'Shimla', lat: 31.1048, lon: 77.1734),
        CityCoords(name: 'Dharamshala', lat: 32.2190, lon: 76.3234),
        CityCoords(name: 'Solan', lat: 30.9045, lon: 77.0967),
        CityCoords(name: 'Mandi', lat: 31.7087, lon: 76.9320),
        CityCoords(name: 'Manali', lat: 32.2432, lon: 77.1892),
      ],
    ),
    'Jammu & Kashmir': IndiaStateData(
      capital: 'Srinagar',
      lat: 34.0837,
      lon: 74.7973,
      cities: [
        CityCoords(name: 'Srinagar', lat: 34.0837, lon: 74.7973),
        CityCoords(name: 'Jammu', lat: 32.7266, lon: 74.8570),
        CityCoords(name: 'Katra', lat: 32.9925, lon: 74.9317),
        CityCoords(name: 'Udhampur', lat: 32.9254, lon: 75.1416),
      ],
    ),
    'Puducherry': IndiaStateData(
      capital: 'Puducherry',
      lat: 11.9416,
      lon: 79.8083,
      cities: [
        CityCoords(name: 'Puducherry', lat: 11.9416, lon: 79.8083),
        CityCoords(name: 'Karaikal', lat: 10.9254, lon: 79.8380),
      ],
    ),
    'Tripura': IndiaStateData(
      capital: 'Agartala',
      lat: 23.8315,
      lon: 91.2868,
      cities: [CityCoords(name: 'Agartala', lat: 23.8315, lon: 91.2868)],
    ),
    'Meghalaya': IndiaStateData(
      capital: 'Shillong',
      lat: 25.5788,
      lon: 91.8933,
      cities: [CityCoords(name: 'Shillong', lat: 25.5788, lon: 91.8933)],
    ),
    'Manipur': IndiaStateData(
      capital: 'Imphal',
      lat: 24.8170,
      lon: 93.9368,
      cities: [CityCoords(name: 'Imphal', lat: 24.8170, lon: 93.9368)],
    ),
    'Nagaland': IndiaStateData(
      capital: 'Kohima',
      lat: 25.6751,
      lon: 94.1086,
      cities: [
        CityCoords(name: 'Kohima', lat: 25.6751, lon: 94.1086),
        CityCoords(name: 'Dimapur', lat: 25.9090, lon: 93.7267),
      ],
    ),
    'Mizoram': IndiaStateData(
      capital: 'Aizawl',
      lat: 23.7271,
      lon: 92.7176,
      cities: [CityCoords(name: 'Aizawl', lat: 23.7271, lon: 92.7176)],
    ),
    'Sikkim': IndiaStateData(
      capital: 'Gangtok',
      lat: 27.3389,
      lon: 88.6065,
      cities: [CityCoords(name: 'Gangtok', lat: 27.3389, lon: 88.6065)],
    ),
    'Arunachal Pradesh': IndiaStateData(
      capital: 'Itanagar',
      lat: 27.0844,
      lon: 93.6053,
      cities: [CityCoords(name: 'Itanagar', lat: 27.0844, lon: 93.6053)],
    ),
    'Ladakh': IndiaStateData(
      capital: 'Leh',
      lat: 34.1526,
      lon: 77.5771,
      cities: [
        CityCoords(name: 'Leh', lat: 34.1526, lon: 77.5771),
        CityCoords(name: 'Kargil', lat: 34.5539, lon: 76.1349),
      ],
    ),
    'Andaman & Nicobar': IndiaStateData(
      capital: 'Port Blair',
      lat: 11.6234,
      lon: 92.7265,
      cities: [
        CityCoords(name: 'Port Blair', lat: 11.6234, lon: 92.7265),
      ],
    ),
  };

  /// Web `INDIAN_CITIES` synonyms (`vedicAstrology.js` lines 567-574).
  static const Map<String, CityCoords> _aliases = {
    'bangalore': CityCoords(name: 'Bangalore', lat: 12.9716, lon: 77.5946),
    'vizag': CityCoords(name: 'Vizag', lat: 17.6868, lon: 83.2185),
    'gurgaon': CityCoords(name: 'Gurgaon', lat: 28.4595, lon: 77.0266),
    'new delhi': CityCoords(name: 'New Delhi', lat: 28.6139, lon: 77.2090),
    'delhi': CityCoords(name: 'Delhi', lat: 28.6139, lon: 77.2090),
    'aurangabad': CityCoords(name: 'Aurangabad', lat: 19.8762, lon: 75.3433),
    'pondicherry': CityCoords(name: 'Pondicherry', lat: 11.9416, lon: 79.8083),
  };

  static final Map<String, CityCoords> _cityIndex = () {
    final index = <String, CityCoords>{};
    for (final entry in states.entries) {
      for (final city in entry.value.cities) {
        index[city.name.toLowerCase()] = city;
      }
    }
    index.addAll(_aliases);
    return index;
  }();

  /// State/UT names in the web `<select>` order (map insertion order).
  static List<String> get stateNames =>
      states.keys.toList(growable: false);

  /// City names of [state] (empty list when the state is unknown).
  static List<String> citiesOf(String? state) {
    final data = states[state?.trim() ?? ''];
    if (data == null) return const <String>[];
    return [for (final c in data.cities) c.name];
  }

  /// Case-insensitive membership test used to decide whether a saved/GPS city
  /// still belongs to the state a user just picked.
  static bool cityInState(String city, String? state) {
    final needle = city.trim().toLowerCase();
    if (needle.isEmpty) return false;
    for (final name in citiesOf(state)) {
      if (name.toLowerCase() == needle) return true;
    }
    return false;
  }

  /// State/UT that lists [city], or null when the city is not in the table.
  static String? stateOfCity(String city) {
    final needle = city.trim().toLowerCase();
    if (needle.isEmpty) return null;
    for (final entry in states.entries) {
      for (final c in entry.value.cities) {
        if (c.name.toLowerCase() == needle) return entry.key;
      }
    }
    return null;
  }

  /// Resolves ephemeris coordinates for a city (or a `"City, State"` place
  /// string), mirroring the web `lookupCityCoords`. Returns null when nothing
  /// matches so callers can keep a manually entered latitude/longitude.
  static CityCoords? lookup(String city, {String? state}) {
    final raw = city.trim();
    if (raw.isEmpty) return null;
    final key = raw.split(',').first.trim().toLowerCase();
    if (key.isEmpty) return null;

    final hinted = state?.trim() ?? '';
    if (hinted.isNotEmpty) {
      final data = states[hinted];
      if (data != null) {
        for (final c in data.cities) {
          final name = c.name.toLowerCase();
          if (name == key) return c;
        }
      }
    }
    final direct = _cityIndex[key];
    if (direct != null) return direct;
    if (hinted.isNotEmpty) {
      for (final c in states[hinted]?.cities ?? const <CityCoords>[]) {
        final name = c.name.toLowerCase();
        if (name.contains(key) || key.contains(name)) return c;
      }
    }
    for (final entry in _cityIndex.entries) {
      if (key.contains(entry.key)) return entry.value;
    }
    return null;
  }
}
