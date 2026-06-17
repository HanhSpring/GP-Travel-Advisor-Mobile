class DemoReviewStore {
  static final Map<String, double> userRatings = {};
  
  static final Map<String, String> userComments = {};

  static final Map<String, double> itineraryOverallRatings = {};
  
  static final Map<String, String> itineraryOverallComments = {};

  static void saveLocationRating(String locationId, double rating, {String? comment}) {
    userRatings[locationId] = rating;
    if (comment != null) userComments[locationId] = comment;
  }

  static double? getLocationRating(String locationId) {
    return userRatings[locationId];
  }

  static void saveItineraryReview(String itineraryId, double rating, {String? comment}) {
    itineraryOverallRatings[itineraryId] = rating;
    if (comment != null) itineraryOverallComments[itineraryId] = comment;
  }
}
