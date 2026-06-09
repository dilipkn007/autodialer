part of 'default.dart';

class ListAllContactsForExportVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  ListAllContactsForExportVariablesBuilder(this._dataConnect, );
  Deserializer<ListAllContactsForExportData> dataDeserializer = (dynamic json)  => ListAllContactsForExportData.fromJson(jsonDecode(json));
  
  Future<QueryResult<ListAllContactsForExportData, void>> execute() {
    return ref().execute();
  }

  QueryRef<ListAllContactsForExportData, void> ref() {
    
    return _dataConnect.query("ListAllContactsForExport", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class ListAllContactsForExportContacts {
  final String? syncStatus;
  final String name;
  final String mobile;
  final String? email;
  final String? whatsapp;
  final String? dateOfBirth;
  final int? age;
  final String? folkAge;
  final String? gender;
  final String? folkId;
  final String? folkGuide;
  final String? folkLevel;
  final String? occupation;
  final String? maritalStatus;
  final String? language;
  final String? livingStatus;
  final String? address;
  final String? permanentAddress;
  final String? city;
  final String? state;
  final String? country;
  final String? higherQualification;
  final String? academicInstitution;
  final String? institutionLocation;
  final String? organization;
  final String? designation;
  final String? organizationLocation;
  final String? residencyInterest;
  final String? origin;
  final String? journey;
  final String? currentStatus;
  final String? lastActivityType;
  final String? lastActivity;
  final String? lastSeen;
  final String? yfhId;
  final String? yfhCity;
  final String? center;
  final String? stay;
  final String? stream;
  final String? highestQualification;
  final String? source;
  final String? talents;
  final String? folkResidencyInterest;
  final String? contactAddress;
  final String? tShirtSize;
  final String? sent;
  final String? isEnabler;
  ListAllContactsForExportContacts.fromJson(dynamic json):
  
  syncStatus = json['syncStatus'] == null ? null : nativeFromJson<String>(json['syncStatus']),
  name = nativeFromJson<String>(json['name']),
  mobile = nativeFromJson<String>(json['mobile']),
  email = json['email'] == null ? null : nativeFromJson<String>(json['email']),
  whatsapp = json['whatsapp'] == null ? null : nativeFromJson<String>(json['whatsapp']),
  dateOfBirth = json['dateOfBirth'] == null ? null : nativeFromJson<String>(json['dateOfBirth']),
  age = json['age'] == null ? null : nativeFromJson<int>(json['age']),
  folkAge = json['folkAge'] == null ? null : nativeFromJson<String>(json['folkAge']),
  gender = json['gender'] == null ? null : nativeFromJson<String>(json['gender']),
  folkId = json['folkId'] == null ? null : nativeFromJson<String>(json['folkId']),
  folkGuide = json['folkGuide'] == null ? null : nativeFromJson<String>(json['folkGuide']),
  folkLevel = json['folkLevel'] == null ? null : nativeFromJson<String>(json['folkLevel']),
  occupation = json['occupation'] == null ? null : nativeFromJson<String>(json['occupation']),
  maritalStatus = json['maritalStatus'] == null ? null : nativeFromJson<String>(json['maritalStatus']),
  language = json['language'] == null ? null : nativeFromJson<String>(json['language']),
  livingStatus = json['livingStatus'] == null ? null : nativeFromJson<String>(json['livingStatus']),
  address = json['address'] == null ? null : nativeFromJson<String>(json['address']),
  permanentAddress = json['permanentAddress'] == null ? null : nativeFromJson<String>(json['permanentAddress']),
  city = json['city'] == null ? null : nativeFromJson<String>(json['city']),
  state = json['state'] == null ? null : nativeFromJson<String>(json['state']),
  country = json['country'] == null ? null : nativeFromJson<String>(json['country']),
  higherQualification = json['higherQualification'] == null ? null : nativeFromJson<String>(json['higherQualification']),
  academicInstitution = json['academicInstitution'] == null ? null : nativeFromJson<String>(json['academicInstitution']),
  institutionLocation = json['institutionLocation'] == null ? null : nativeFromJson<String>(json['institutionLocation']),
  organization = json['organization'] == null ? null : nativeFromJson<String>(json['organization']),
  designation = json['designation'] == null ? null : nativeFromJson<String>(json['designation']),
  organizationLocation = json['organizationLocation'] == null ? null : nativeFromJson<String>(json['organizationLocation']),
  residencyInterest = json['residencyInterest'] == null ? null : nativeFromJson<String>(json['residencyInterest']),
  origin = json['origin'] == null ? null : nativeFromJson<String>(json['origin']),
  journey = json['journey'] == null ? null : nativeFromJson<String>(json['journey']),
  currentStatus = json['currentStatus'] == null ? null : nativeFromJson<String>(json['currentStatus']),
  lastActivityType = json['lastActivityType'] == null ? null : nativeFromJson<String>(json['lastActivityType']),
  lastActivity = json['lastActivity'] == null ? null : nativeFromJson<String>(json['lastActivity']),
  lastSeen = json['lastSeen'] == null ? null : nativeFromJson<String>(json['lastSeen']),
  yfhId = json['yfhId'] == null ? null : nativeFromJson<String>(json['yfhId']),
  yfhCity = json['yfhCity'] == null ? null : nativeFromJson<String>(json['yfhCity']),
  center = json['center'] == null ? null : nativeFromJson<String>(json['center']),
  stay = json['stay'] == null ? null : nativeFromJson<String>(json['stay']),
  stream = json['stream'] == null ? null : nativeFromJson<String>(json['stream']),
  highestQualification = json['highestQualification'] == null ? null : nativeFromJson<String>(json['highestQualification']),
  source = json['source'] == null ? null : nativeFromJson<String>(json['source']),
  talents = json['talents'] == null ? null : nativeFromJson<String>(json['talents']),
  folkResidencyInterest = json['folkResidencyInterest'] == null ? null : nativeFromJson<String>(json['folkResidencyInterest']),
  contactAddress = json['contactAddress'] == null ? null : nativeFromJson<String>(json['contactAddress']),
  tShirtSize = json['tShirtSize'] == null ? null : nativeFromJson<String>(json['tShirtSize']),
  sent = json['sent'] == null ? null : nativeFromJson<String>(json['sent']),
  isEnabler = json['isEnabler'] == null ? null : nativeFromJson<String>(json['isEnabler']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListAllContactsForExportContacts otherTyped = other as ListAllContactsForExportContacts;
    return syncStatus == otherTyped.syncStatus && 
    name == otherTyped.name && 
    mobile == otherTyped.mobile && 
    email == otherTyped.email && 
    whatsapp == otherTyped.whatsapp && 
    dateOfBirth == otherTyped.dateOfBirth && 
    age == otherTyped.age && 
    folkAge == otherTyped.folkAge && 
    gender == otherTyped.gender && 
    folkId == otherTyped.folkId && 
    folkGuide == otherTyped.folkGuide && 
    folkLevel == otherTyped.folkLevel && 
    occupation == otherTyped.occupation && 
    maritalStatus == otherTyped.maritalStatus && 
    language == otherTyped.language && 
    livingStatus == otherTyped.livingStatus && 
    address == otherTyped.address && 
    permanentAddress == otherTyped.permanentAddress && 
    city == otherTyped.city && 
    state == otherTyped.state && 
    country == otherTyped.country && 
    higherQualification == otherTyped.higherQualification && 
    academicInstitution == otherTyped.academicInstitution && 
    institutionLocation == otherTyped.institutionLocation && 
    organization == otherTyped.organization && 
    designation == otherTyped.designation && 
    organizationLocation == otherTyped.organizationLocation && 
    residencyInterest == otherTyped.residencyInterest && 
    origin == otherTyped.origin && 
    journey == otherTyped.journey && 
    currentStatus == otherTyped.currentStatus && 
    lastActivityType == otherTyped.lastActivityType && 
    lastActivity == otherTyped.lastActivity && 
    lastSeen == otherTyped.lastSeen && 
    yfhId == otherTyped.yfhId && 
    yfhCity == otherTyped.yfhCity && 
    center == otherTyped.center && 
    stay == otherTyped.stay && 
    stream == otherTyped.stream && 
    highestQualification == otherTyped.highestQualification && 
    source == otherTyped.source && 
    talents == otherTyped.talents && 
    folkResidencyInterest == otherTyped.folkResidencyInterest && 
    contactAddress == otherTyped.contactAddress && 
    tShirtSize == otherTyped.tShirtSize && 
    sent == otherTyped.sent && 
    isEnabler == otherTyped.isEnabler;
    
  }
  @override
  int get hashCode => Object.hashAll([syncStatus.hashCode, name.hashCode, mobile.hashCode, email.hashCode, whatsapp.hashCode, dateOfBirth.hashCode, age.hashCode, folkAge.hashCode, gender.hashCode, folkId.hashCode, folkGuide.hashCode, folkLevel.hashCode, occupation.hashCode, maritalStatus.hashCode, language.hashCode, livingStatus.hashCode, address.hashCode, permanentAddress.hashCode, city.hashCode, state.hashCode, country.hashCode, higherQualification.hashCode, academicInstitution.hashCode, institutionLocation.hashCode, organization.hashCode, designation.hashCode, organizationLocation.hashCode, residencyInterest.hashCode, origin.hashCode, journey.hashCode, currentStatus.hashCode, lastActivityType.hashCode, lastActivity.hashCode, lastSeen.hashCode, yfhId.hashCode, yfhCity.hashCode, center.hashCode, stay.hashCode, stream.hashCode, highestQualification.hashCode, source.hashCode, talents.hashCode, folkResidencyInterest.hashCode, contactAddress.hashCode, tShirtSize.hashCode, sent.hashCode, isEnabler.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (syncStatus != null) {
      json['syncStatus'] = nativeToJson<String?>(syncStatus);
    }
    json['name'] = nativeToJson<String>(name);
    json['mobile'] = nativeToJson<String>(mobile);
    if (email != null) {
      json['email'] = nativeToJson<String?>(email);
    }
    if (whatsapp != null) {
      json['whatsapp'] = nativeToJson<String?>(whatsapp);
    }
    if (dateOfBirth != null) {
      json['dateOfBirth'] = nativeToJson<String?>(dateOfBirth);
    }
    if (age != null) {
      json['age'] = nativeToJson<int?>(age);
    }
    if (folkAge != null) {
      json['folkAge'] = nativeToJson<String?>(folkAge);
    }
    if (gender != null) {
      json['gender'] = nativeToJson<String?>(gender);
    }
    if (folkId != null) {
      json['folkId'] = nativeToJson<String?>(folkId);
    }
    if (folkGuide != null) {
      json['folkGuide'] = nativeToJson<String?>(folkGuide);
    }
    if (folkLevel != null) {
      json['folkLevel'] = nativeToJson<String?>(folkLevel);
    }
    if (occupation != null) {
      json['occupation'] = nativeToJson<String?>(occupation);
    }
    if (maritalStatus != null) {
      json['maritalStatus'] = nativeToJson<String?>(maritalStatus);
    }
    if (language != null) {
      json['language'] = nativeToJson<String?>(language);
    }
    if (livingStatus != null) {
      json['livingStatus'] = nativeToJson<String?>(livingStatus);
    }
    if (address != null) {
      json['address'] = nativeToJson<String?>(address);
    }
    if (permanentAddress != null) {
      json['permanentAddress'] = nativeToJson<String?>(permanentAddress);
    }
    if (city != null) {
      json['city'] = nativeToJson<String?>(city);
    }
    if (state != null) {
      json['state'] = nativeToJson<String?>(state);
    }
    if (country != null) {
      json['country'] = nativeToJson<String?>(country);
    }
    if (higherQualification != null) {
      json['higherQualification'] = nativeToJson<String?>(higherQualification);
    }
    if (academicInstitution != null) {
      json['academicInstitution'] = nativeToJson<String?>(academicInstitution);
    }
    if (institutionLocation != null) {
      json['institutionLocation'] = nativeToJson<String?>(institutionLocation);
    }
    if (organization != null) {
      json['organization'] = nativeToJson<String?>(organization);
    }
    if (designation != null) {
      json['designation'] = nativeToJson<String?>(designation);
    }
    if (organizationLocation != null) {
      json['organizationLocation'] = nativeToJson<String?>(organizationLocation);
    }
    if (residencyInterest != null) {
      json['residencyInterest'] = nativeToJson<String?>(residencyInterest);
    }
    if (origin != null) {
      json['origin'] = nativeToJson<String?>(origin);
    }
    if (journey != null) {
      json['journey'] = nativeToJson<String?>(journey);
    }
    if (currentStatus != null) {
      json['currentStatus'] = nativeToJson<String?>(currentStatus);
    }
    if (lastActivityType != null) {
      json['lastActivityType'] = nativeToJson<String?>(lastActivityType);
    }
    if (lastActivity != null) {
      json['lastActivity'] = nativeToJson<String?>(lastActivity);
    }
    if (lastSeen != null) {
      json['lastSeen'] = nativeToJson<String?>(lastSeen);
    }
    if (yfhId != null) {
      json['yfhId'] = nativeToJson<String?>(yfhId);
    }
    if (yfhCity != null) {
      json['yfhCity'] = nativeToJson<String?>(yfhCity);
    }
    if (center != null) {
      json['center'] = nativeToJson<String?>(center);
    }
    if (stay != null) {
      json['stay'] = nativeToJson<String?>(stay);
    }
    if (stream != null) {
      json['stream'] = nativeToJson<String?>(stream);
    }
    if (highestQualification != null) {
      json['highestQualification'] = nativeToJson<String?>(highestQualification);
    }
    if (source != null) {
      json['source'] = nativeToJson<String?>(source);
    }
    if (talents != null) {
      json['talents'] = nativeToJson<String?>(talents);
    }
    if (folkResidencyInterest != null) {
      json['folkResidencyInterest'] = nativeToJson<String?>(folkResidencyInterest);
    }
    if (contactAddress != null) {
      json['contactAddress'] = nativeToJson<String?>(contactAddress);
    }
    if (tShirtSize != null) {
      json['tShirtSize'] = nativeToJson<String?>(tShirtSize);
    }
    if (sent != null) {
      json['sent'] = nativeToJson<String?>(sent);
    }
    if (isEnabler != null) {
      json['isEnabler'] = nativeToJson<String?>(isEnabler);
    }
    return json;
  }

  ListAllContactsForExportContacts({
    this.syncStatus,
    required this.name,
    required this.mobile,
    this.email,
    this.whatsapp,
    this.dateOfBirth,
    this.age,
    this.folkAge,
    this.gender,
    this.folkId,
    this.folkGuide,
    this.folkLevel,
    this.occupation,
    this.maritalStatus,
    this.language,
    this.livingStatus,
    this.address,
    this.permanentAddress,
    this.city,
    this.state,
    this.country,
    this.higherQualification,
    this.academicInstitution,
    this.institutionLocation,
    this.organization,
    this.designation,
    this.organizationLocation,
    this.residencyInterest,
    this.origin,
    this.journey,
    this.currentStatus,
    this.lastActivityType,
    this.lastActivity,
    this.lastSeen,
    this.yfhId,
    this.yfhCity,
    this.center,
    this.stay,
    this.stream,
    this.highestQualification,
    this.source,
    this.talents,
    this.folkResidencyInterest,
    this.contactAddress,
    this.tShirtSize,
    this.sent,
    this.isEnabler,
  });
}

@immutable
class ListAllContactsForExportData {
  final List<ListAllContactsForExportContacts> contacts;
  ListAllContactsForExportData.fromJson(dynamic json):
  
  contacts = (json['contacts'] as List<dynamic>)
        .map((e) => ListAllContactsForExportContacts.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListAllContactsForExportData otherTyped = other as ListAllContactsForExportData;
    return contacts == otherTyped.contacts;
    
  }
  @override
  int get hashCode => contacts.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['contacts'] = contacts.map((e) => e.toJson()).toList();
    return json;
  }

  ListAllContactsForExportData({
    required this.contacts,
  });
}

