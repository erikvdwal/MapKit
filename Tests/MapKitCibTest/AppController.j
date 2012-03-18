/*
 * AppController.j
 * MapKitCibTest
 *
 * Created by You on March 1, 2012.
 * Copyright 2012, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>
@import "../../MapKit.j"

@implementation AppController : CPObject
{
    CPWindow    theWindow; //this "outlet" is connected automatically by the Cib
    @outlet MKMapView mapView;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    // This is called when the application is done loading.
}

- (void)awakeFromCib
{
    [mapView setZoomLevel:20];
    [mapView setDelegate:self];
}

- (void)mapViewDidFinishLoadingMap:(MKMapView)aMapView
{
    var address = @"12 rue de vaugirard, paris, france";

    var geocoder = [[MKGeocoder alloc] init];
    [geocoder geocodeAddressString:address inRegion:nil completionHandler:function(placemarks, error)
    {
        if (error)
            CPLogConsole(error);
        else
        {
            var location = [placemarks[0] coordinate];
            var annotation = [[MKAnnotation alloc] init];
            [annotation setCoordinate:location];
            
            [mapView setCenterCoordinate:location];
            [mapView addAnnotation:annotation];
        }
    }];
}

@end
