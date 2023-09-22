class PredictedStocks{

  String date;
  Map<String, String> allStocks;

  PredictedStocks({required this.date, required this.allStocks});


  factory PredictedStocks.fromJson(Map<String, dynamic> json) {

     Map<String, String> allStocks =  json.map((key, value) => MapEntry(key, value.toString()));

     allStocks.removeWhere((key, value) => key == 'date');
    return PredictedStocks(
      date: json['Date'],
      allStocks: allStocks
    );
  }

}