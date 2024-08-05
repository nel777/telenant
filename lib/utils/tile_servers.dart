const yourMapBoxAccessToken = '';

String google(int z, int x, int y) {
  //Google Maps
  final url =
      'https://www.google.com/maps/vt/pb=!1m4!1m3!1i$z!2i$x!3i$y!2m3!1e0!2sm!3i420120488!3m7!2sen!5e1105!12m4!1e68!2m2!1sset!2sRoadmap!4e0!5m1!1e0!23i4111425';
  return url;
}

String mapbox(int z, int x, int y) {
  //Mapbox Streets
  final url =
      'https://api.mapbox.com/styles/v1/mapbox/streets-v11/tiles/$z/$x/$y?access_token=$yourMapBoxAccessToken';

  return url;
}
