@import "MKPlacemark.j"

@implementation MKGeocoder : CPObject
{
    BOOL geocoding @accessors(readonly);
    id _geocoder;
}

- (id)init
{
    self = [super init];
    geocoding = NO;
    _geocoder = new google.maps.Geocoder();
    
    return self;
}

- (void)geocodeAddressString:(CPString)anAddress inRegion:(id/*MKCoordinateRegion*/)region completionHandler:(Function /*(placemarks, error)*/)completionHandler
{
    var request = {address:anAddress};
    if (region)
    {
        var bounds = LatLngBoundsFromMKCoordinateRegion(region);
        request['bounds'] = bounds;
    }
    
    [self _geocodeWithRequest:request completionHandler:completionHandler];
}

- (void)reverseGeocodeLocation:(id/*CLLocationCoordinate2D*/)location completionHandler:(Function /*(placemarks, error)*/)completionHandler
{
    var latLng = LatLngFromCLLocationCoordinate2D(location);
    [self _geocodeWithRequest:{latLng:latLng} completionHandler:completionHandler];
}

- (void)_geocodeWithRequest:(Object)properties completionHandler:(Function /*(placemarks, error)*/)completionHandler
{
    geocoding = YES;		
    _geocoder.geocode(properties, function(results, status) 
    {
        var placemarks,
            error;

        if (status == google.maps.GeocoderStatus.OK)
        {
            error = nil;
            placemarks = [CPArray array];
            [results enumerateObjectsUsingBlock:function(result, idx)
            {
                var placemark = [[MKPlacemark alloc] initWithJSON:result];
                [placemarks addObject:placemark];
            }];
        }
        else 
        {
            error = status;
            placemarks = nil;
        }
        
        completionHandler(placemarks, error);
        geocoding = NO;
    });
}

@end