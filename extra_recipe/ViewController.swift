//
//  ViewController.swift
//  extra_recipe
//
//  Created by Ian Beer on 1/23/17.
//  Copyright © 2017 Ian Beer. All rights reserved.
//

import UIKit

class ViewController: UIViewController, DrawerToggleViewDelegate {
    @IBOutlet weak var goButton: SexyFillButton!
    @IBOutlet weak var deviceLabel: UILabel!
    @IBOutlet weak var progressContainerView: UIVisualEffectView!
    @IBOutlet weak var progressView: ProgressView!
    @IBOutlet weak var drawerToggleView: DrawerToggleView!
    @IBOutlet weak var mainContentView: UIView!
    @IBOutlet weak var menuOpenedConstraint: NSLayoutConstraint!
    @IBOutlet weak var menuClosedConstraint: NSLayoutConstraint!
    @IBOutlet weak var menuDarkeningView: UIView!
    @IBOutlet weak var substrateEnabledSwitch: UISwitch!
    @IBOutlet weak var pathSizeSwitch: UISwitch!
    @IBOutlet weak var creditsLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    var hasStarted = false
    var pathSize = 256;
    
    let substrateEnabledSwitchConstant = "substrateEnabledSwitch"
    let experimentalPathSizeSwitchConstant = "experimentalPathSizeSwitch"
    
    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Defaults
        NSLog("Extra Recipe (AppleBetas UI) v\(version)")
        let defaults = UserDefaults.standard
        defaults.register(defaults: [substrateEnabledSwitchConstant : true])
        defaults.register(defaults: [experimentalPathSizeSwitchConstant : false])
        substrateEnabledSwitch.isOn = defaults.bool(forKey: substrateEnabledSwitchConstant)
        pathSizeSwitch.isOn = defaults.bool(forKey: experimentalPathSizeSwitchConstant)
        
        creditsLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(creditsPopup(tapGestureRecognizer:))))
        titleLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(titlePopup(tapGestureRecognizer:))))
        progressContainerView.effect = nil
        progressView.alpha = 0
        progressContainerView.isHidden = true
        substrateEnable = (substrateEnabledSwitch.isOn ? 1 : 0);
        progressView.updateProgressState(with: ProgressState(text: "Working on it…", image: nil, spinnerState: .none, overrideRingColour: nil), animated: false)
        drawerToggleView.delegate = self
        menuDarkeningView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ViewController.menuDarkeningViewTapped)))
        loadDeviceData()
        substrateEnabled(self)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        // Hide menu on rotation/view size change
        if drawerToggleView.isOpen {
            setDrawer(opened: false)
        }
    }
    
    @IBAction func substrateEnabled(_ sender: Any) {
        substrateEnable = (substrateEnabledSwitch.isOn ? 1 : 0);
        saveSettings()
        let output = "Enable Substrate: \(Bool(substrateEnable as NSNumber))"
        print(output)
        NSLog(output)
    }
    
    @IBAction func pathSize(_ sender: Any) {
        pathSize = (pathSizeSwitch.isOn ? 4096 : 256);
        saveSettings()
        let output = "Path Size: \(pathSize)"
        print(output)
        NSLog(output)
    }
    
    func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(substrateEnabledSwitch.isOn, forKey: substrateEnabledSwitchConstant)
        defaults.set(pathSizeSwitch.isOn, forKey: experimentalPathSizeSwitchConstant)
    }
    
    func titlePopup(tapGestureRecognizer: UITapGestureRecognizer) {
        let body = "Extra Recipe (AppleBetas UI) v\(version)\nBuild Date: \(compileDate)"
        let link = "https://github.com/mullak99/extra_recipe"
        let alert = UIAlertController(title: "Extra Recipe + Yalu", message: body, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Github",
                                      style: UIAlertActionStyle.default, handler: {
                                        (action:UIAlertAction!) -> Void in
                                        UIApplication.shared.openURL(NSURL(string: link)! as URL)
        }))
        alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func creditsPopup(tapGestureRecognizer: UITapGestureRecognizer) {
        let credits = "• Ian Beer for the kernel exploit\n• qwertyoruiop for the memprot bypass\n• Pwn20wnd for the offsets\n• AppleBetas for the UI\n• mullak99 for updating AppleBetas PR";
        let alert = UIAlertController(title: "Credits", message: credits, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func bang(_ sender: UIButton) {
        doJailbreak()
    }
    
    func doJailbreak() {
        if !hasStarted {
            hasStarted = true
            progressContainerView.effect = nil
            progressView.alpha = 0
            progressContainerView.alpha = 1
            progressContainerView.isHidden = false
            progressView.updateProgressState(with: ProgressState(text: "Working on it…", image: nil, spinnerState: .spinning, overrideRingColour: nil), animated: true)
            UIView.animate(withDuration: 0.25, animations: {
                self.progressContainerView.effect = UIBlurEffect(style: .dark)
                self.progressView.alpha = 1
            })
            
            OperationQueue().addOperation {
                let result = jb_go()
                OperationQueue.main.addOperation {
                    self.handle(result: JailbreakStatus.status(from: result))
                }
            }
        }
    }
    
    private func handle(result: JailbreakStatus) {
        self.progressView.updateProgressState(with: result.progressState, animated: true)
        if result.shouldShowAlert {
            let alert = UIAlertController(title: result.alertTitle, message: result.alertMessage, preferredStyle: .alert)
            if result.shouldAlertHaveExitButton {
                alert.addAction(UIAlertAction(title: "Exit", style: .default, handler: { _ in
                    UIApplication.shared.performGracefulExit()
                }))
            }
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { _ in
                OperationQueue.main.addOperation {
                    self.present(alert, animated: true, completion: nil)
                }
            })
        }
    }
    
    private func loadDeviceData() {
        let deviceName = Device().getDeviceName(extra: false)
        let iosVersion = UIDevice.current.systemVersion
        let supported = init_offsets() == 0
        let jailed = Bool(isJailed() as NSNumber)
        deviceLabel.text = "\(jailed ? "Jailed " : "Jailbroken ")\(deviceName) (iOS \(iosVersion))\nYour device is \(supported ? "" : "not ")supported."
        if (supported && jailed) { goButton.isEnabled = true }
        else { goButton.isEnabled = false }
        let output = "\(jailed ? "Jailed " : "Jailbroken ")\(deviceName) (iOS \(iosVersion)) is \(supported ? "" : "not ")supported.";
        print(output)
        NSLog(output)
    }
    
    
    func setDrawer(opened open: Bool) {
        menuOpenedConstraint.isActive = open
        menuClosedConstraint.isActive = !open
        menuDarkeningView.isUserInteractionEnabled = open
        UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 1, animations: {
            self.drawerToggleView.isOpen = open
            self.menuDarkeningView.alpha = open ? 1 : 0
            self.mainContentView.alpha = open ? 0.6 : 1
            self.mainContentView.transform = open ? CGAffineTransform.identity.scaledBy(x: 0.85, y: 0.85) : .identity
            self.view.layoutIfNeeded()
        }, completion: nil)
    }

    func menuDarkeningViewTapped() {
        setDrawer(opened: false)
    }
    
    // MARK: - Drawer Toggle View Delegate
    
    func drawerToggleViewTapped(_ view: DrawerToggleView) {
        setDrawer(opened: !view.isOpen)
    }
    
    var compileDate:Date
    {
        let bundleName = Bundle.main.infoDictionary!["CFBundleName"] as? String ?? "Info.plist"
        if let infoPath = Bundle.main.path(forResource: bundleName, ofType: nil),
            let infoAttr = try? FileManager.default.attributesOfItem(atPath: infoPath),
            let infoDate = infoAttr[FileAttributeKey.creationDate] as? Date
        { return infoDate }
        return Date()
    }
    
}

