//
//  MapView.swift
//  animated-octo-happiness-ios
//
//  Created by Auto Agent on 8/17/25.
//

import SwiftUI
import MapKit

class TreasureMapAnnotation: NSObject, MKAnnotation {
    let treasure: Treasure
    dynamic var coordinate: CLLocationCoordinate2D
    var title: String? { treasure.title }
    var subtitle: String? { treasure.treasureDescription }
    
    init(treasure: Treasure) {
        self.treasure = treasure
        self.coordinate = treasure.coordinate
        super.init()
    }
}

struct MapView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var treasureStore = TreasureStore()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var showingAddTreasureAlert = false
    @State private var tappedCoordinate: CLLocationCoordinate2D?
    @State private var newTreasureName = ""
    @State private var newTreasureDescription = ""
    @State private var selectedTreasure: Treasure?
    @State private var showingTreasureDetails = false
    @State private var lastKnownLocation: CLLocationCoordinate2D?
    
    var body: some View {
        ZStack {
            MapViewRepresentable(
                region: $region,
                treasures: treasureStore.treasures,
                onTapLocation: { coordinate in
                    tappedCoordinate = coordinate
                    showingAddTreasureAlert = true
                },
                onTapTreasure: { treasure in
                    selectedTreasure = treasure
                    showingTreasureDetails = true
                }
            )
            .onAppear {
                locationManager.requestLocationPermission()
                if let userLocation = locationManager.currentLocation?.coordinate {
                    region.center = userLocation
                    lastKnownLocation = userLocation
                }
            }
            .onReceive(locationManager.$currentLocation) { newLocation in
                if let location = newLocation?.coordinate,
                   lastKnownLocation == nil ||
                   abs(location.latitude - (lastKnownLocation?.latitude ?? 0)) > 0.0001 ||
                   abs(location.longitude - (lastKnownLocation?.longitude ?? 0)) > 0.0001 {
                    withAnimation {
                        region.center = location
                        lastKnownLocation = location
                    }
                }
            }
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    
                    Button(action: centerOnUserLocation) {
                        Image(systemName: "location.fill")
                            .padding()
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(radius: 3)
                    }
                    .padding()
                }
            }
        }
        .alert("Add Treasure", isPresented: $showingAddTreasureAlert) {
            TextField("Treasure Name", text: $newTreasureName)
            TextField("Description", text: $newTreasureDescription)
            Button("Cancel", role: .cancel) {
                resetAddTreasureForm()
            }
            Button("Add") {
                if let coordinate = tappedCoordinate, !newTreasureName.isEmpty {
                    Task {
                        let treasure = Treasure(
                            title: newTreasureName,
                            description: newTreasureDescription,
                            coordinate: coordinate
                        )
                        try await treasureStore.addTreasure(treasure)
                        resetAddTreasureForm()
                    }
                }
            }
        } message: {
            Text("Enter details for the new treasure")
        }
        .sheet(isPresented: $showingTreasureDetails) {
            if let treasure = selectedTreasure {
                TreasureDetailView(treasure: treasure, treasureStore: treasureStore)
            }
        }
    }
    
    private func centerOnUserLocation() {
        if let location = locationManager.currentLocation?.coordinate {
            withAnimation {
                region.center = location
            }
        }
    }
    
    private func resetAddTreasureForm() {
        newTreasureName = ""
        newTreasureDescription = ""
        tappedCoordinate = nil
    }
}

struct MapViewRepresentable: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    let treasures: [Treasure]
    let onTapLocation: (CLLocationCoordinate2D) -> Void
    let onTapTreasure: (Treasure) -> Void
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.setRegion(region, animated: false)
        
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        mapView.addGestureRecognizer(tapGesture)
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.setRegion(region, animated: true)
        
        let currentAnnotations = mapView.annotations.compactMap { $0 as? TreasureMapAnnotation }
        let currentTreasureIds = Set(currentAnnotations.map { $0.treasure.id })
        let newTreasureIds = Set(treasures.map { $0.id })
        
        let toRemove = currentAnnotations.filter { !newTreasureIds.contains($0.treasure.id) }
        mapView.removeAnnotations(toRemove as [any MKAnnotation])
        
        let toAdd = treasures.filter { !currentTreasureIds.contains($0.id) }
        let newAnnotations = toAdd.map { TreasureMapAnnotation(treasure: $0) }
        mapView.addAnnotations(newAnnotations)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewRepresentable
        
        init(_ parent: MapViewRepresentable) {
            self.parent = parent
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let mapView = gesture.view as? MKMapView else { return }
            
            let tapPoint = gesture.location(in: mapView)
            let coordinate = mapView.convert(tapPoint, toCoordinateFrom: mapView)
            
            parent.onTapLocation(coordinate)
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let treasureAnnotation = annotation as? TreasureAnnotation else {
                return nil
            }
            
            let identifier = "TreasurePin"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
                let button = UIButton(type: .detailDisclosure)
                annotationView?.rightCalloutAccessoryView = button
            } else {
                annotationView?.annotation = annotation
            }
            
            annotationView?.markerTintColor = treasureAnnotation.treasure.isCollected ? .yellow : .red
            annotationView?.glyphImage = UIImage(systemName: treasureAnnotation.treasure.isCollected ? "star.fill" : "mappin.circle.fill")
            
            return annotationView
        }
        
        func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
            guard let treasureAnnotation = view.annotation as? TreasureAnnotation else { return }
            parent.onTapTreasure(treasureAnnotation.treasure)
        }
        
        func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
            parent.region = mapView.region
        }
    }
}


#Preview {
    MapView()
}