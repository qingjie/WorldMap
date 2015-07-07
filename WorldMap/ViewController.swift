//
//  ViewController.swift
//  WorldMap
//
//  Created by qingjiezhao on 7/7/15.
//  Copyright (c) 2015 qingjiezhao. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController , UITableViewDataSource , UITableViewDelegate , MKMapViewDelegate , UIPopoverPresentationControllerDelegate {

    var contentController : UITableViewController!
    var areaListTable : UITableView!
    var selectedItemIndex : Int!
    var regionNames = [ "Africa", "East Asia and the Pacific","Central Europe and the Baltics","Europe and Central Asia","Latin America and the Caribbean","Middle East and North Africa","South Asia","European Union","North America", "North Africa", "South Asia"]
    var regionCodes = ["AFR","CEA","CEB","CEU","CLA","CME","CSA","EUU","NAC","NAF","SAS"]
    
    
    @IBOutlet weak var add: UIBarButtonItem!
    @IBOutlet weak var mapView: MKMapView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        contentController = UITableViewController()
        areaListTable = UITableView()
        areaListTable.dataSource = self
        areaListTable.delegate = self
        contentController.tableView = areaListTable
        selectedItemIndex = -1
        mapView.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    @IBAction func add(sender : AnyObject) {
        
        contentController.modalPresentationStyle = UIModalPresentationStyle.Popover
        var popOverPC = contentController.popoverPresentationController! as UIPopoverPresentationController
        popOverPC.barButtonItem = add
        popOverPC.permittedArrowDirections = UIPopoverArrowDirection.Any
        popOverPC.delegate = self
        presentViewController( contentController, animated:true, completion: nil)
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        var cell = tableView.dequeueReusableCellWithIdentifier("cell") as? UITableViewCell
        if cell == nil {
            cell = UITableViewCell(style: UITableViewCellStyle.Value1, reuseIdentifier: "cell")
            cell?.textLabel?.text = regionNames[indexPath.row]
        }
        cell!.accessoryType = UITableViewCellAccessoryType.None
        return cell!
        
        
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return regionNames.count
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var selectedCell  = tableView.cellForRowAtIndexPath(indexPath)! as UITableViewCell
        
        selectedCell.accessoryType = UITableViewCellAccessoryType.Checkmark
        selectedItemIndex = indexPath.row
        
    }
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        var deselectedCell = tableView.cellForRowAtIndexPath(indexPath)! as UITableViewCell
        deselectedCell.accessoryType = UITableViewCellAccessoryType.None
    }

    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return .FullScreen
    }
    
    func presentationController(controller: UIPresentationController, viewControllerForAdaptivePresentationStyle style: UIModalPresentationStyle) -> UIViewController? {
        
        var navController = UINavigationController(rootViewController: controller.presentedViewController)
        controller.presentedViewController.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Done, target: self, action: "done")
        areaListTable.reloadData()
        selectedItemIndex = -1
        return navController
    }
    
    func done(){
        presentedViewController?.dismissViewControllerAnimated(true, completion: nil)
        mapSearch()
    }
    
    func prepareForPopoverPresentation(popoverPresentationController: UIPopoverPresentationController) {
        areaListTable.reloadData()
        selectedItemIndex = -1
        
    }
    
    func popoverPresentationControllerDidDismissPopover(popoverPresentationController: UIPopoverPresentationController) {
        mapSearch()
    }
    
    func mapSearch(){
        
        if selectedItemIndex == -1 {
            return
        }
        let url:NSURL = NSURL(string: "http://api.worldbank.org/country?per_page=100&region=\(regionCodes[selectedItemIndex])&format=json")!
        let task = NSURLSession.sharedSession().dataTaskWithURL(url, completionHandler: { (data,response,error) -> Void in
            var json : AnyObject! = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: nil)
            let dataArray = json.objectAtIndex(1) as! NSArray
            self.displayRegionIncomeLevel(dataArray as [AnyObject])
        
        })
        // Call the resume() method to start the NSURLSession task
        task.resume()
    
    }
    
    func displayRegionIncomeLevel(data:[AnyObject]){

        if data.count == 0{
            return
        }
        
        //1
        // Change the Map Region to the first lon/lat in the array of dictionaries
        let regionLongitude = data[1]["longitude"]
        let regionLatitude = data[1]["latitude"]
        
        let center = CLLocationCoordinate2D(latitude: (regionLatitude as! NSString).doubleValue, longitude: (regionLongitude as! NSString).doubleValue)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10))
        self.mapView.setRegion(region, animated: true)
        //Loop through all items and display them on the map
        var lon:Double!
        var lat:Double!
        var annotationView:MKPinAnnotationView!
        var pointAnnoation:CustomPointAnnotation!
        //2
        for item in data{
            let obj = item as! Dictionary<String,AnyObject>
            lon = obj["longitude"]!.doubleValue
            lat = obj["latitude"]!.doubleValue
            pointAnnoation = CustomPointAnnotation()
            let incomeLevel = obj["incomeLevel"] as! Dictionary<String, AnyObject>
            let incomeLevelValue = (incomeLevel["value"] as! String)
            if incomeLevelValue == "High income: OECD" || incomeLevelValue == "High income: nonOECD"{
                pointAnnoation.pinCustomImageName = "High income"
            }else{
                 pointAnnoation.pinCustomImageName = (incomeLevel["value"] as! String)
            }
            //3
            pointAnnoation.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            var countryCode = obj["id"] as? String
            pointAnnoation.title = obj["name"] as! String
            pointAnnoation.subtitle = obj["capitalCity"] as! String
            annotationView = MKPinAnnotationView(annotation: pointAnnoation, reuseIdentifier: "pin")
            self.mapView.addAnnotation(annotationView.annotation)
            
        }
        
        
    }
    
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        
        let reuseIdentifier = "pin"
        var v = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseIdentifier)
        if v == nil {
            v = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
            v.canShowCallout = true
        }else{
            v.annotation = annotation
        }
        let customPointAnnotation = annotation as! CustomPointAnnotation
        v.image = UIImage(named:customPointAnnotation.pinCustomImageName)
        return v
        
        
    }
}

