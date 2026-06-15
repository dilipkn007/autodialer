part of 'default.dart';

class GetContactCountByCenterVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  GetContactCountByCenterVariablesBuilder(this._dataConnect, );
  Deserializer<GetContactCountByCenterData> dataDeserializer = (dynamic json)  => GetContactCountByCenterData.fromJson(jsonDecode(json));
  
  Future<QueryResult<GetContactCountByCenterData, void>> execute() {
    return ref().execute();
  }

  QueryRef<GetContactCountByCenterData, void> ref() {
    
    return _dataConnect.query("GetContactCountByCenter", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class GetContactCountByCenterData {
  final List<AnyValue>? counts;
  GetContactCountByCenterData.fromJson(dynamic json):
  
  counts = json['counts'] == null ? null : (json['counts'] as List<dynamic>)
        .map((e) => AnyValue.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetContactCountByCenterData otherTyped = other as GetContactCountByCenterData;
    return counts == otherTyped.counts;
    
  }
  @override
  int get hashCode => counts.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (counts != null) {
      json['counts'] = counts?.map((e) => e!.toJson()).toList();
    }
    return json;
  }

  GetContactCountByCenterData({
    this.counts,
  });
}

