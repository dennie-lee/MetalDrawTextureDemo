//
//  ViewController.swift
//  MetalDrawTextureDemo
//
//  Created by liqinghua on 11.5.23.
//

import UIKit
import MetalKit
import Metal

class ViewController: UIViewController {
    private var mtkView : MTKView!
    private var imageRender : ImageRender?
    
    private var button : UIButton!
    private var switchX,switchY,switchZ :UISwitch!
    private var cubeImageRender : CubeRender?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageRenderDemo()
        //下面的例子是图片渲染到锥体中，查看效果，请注释上面的例子代码，开启下面的代码
        //cubeImageRenderDemo()
    }
    
    private func imageRenderDemo(){
        mtkView = MTKView(frame: view.bounds)
        view.addSubview(mtkView)
        mtkView.device = MTLCreateSystemDefaultDevice()
        
        imageRender = ImageRender(mtkView: mtkView,imageName: "test_two")
        imageRender?.mtkView(mtkView, drawableSizeWillChange: mtkView.drawableSize)
        mtkView.delegate = imageRender
    }
    
    private func cubeImageRenderDemo(){
        view.backgroundColor = UIColor.orange
        
        //let viewFrame = CGRect(x: 0, y: (view.bounds.height - view.bounds.width) / 2,
        //                   width: view.bounds.width, height: view.bounds.width)
        mtkView = MTKView(frame: view.bounds)
        view.addSubview(mtkView)
        mtkView.device = MTLCreateSystemDefaultDevice()
        
        cubeImageRender = CubeRender(mtkView: mtkView,imageName: "test_two")
        cubeImageRender?.mtkView(mtkView, drawableSizeWillChange: mtkView.drawableSize)
        mtkView.delegate = cubeImageRender
        
        cubeController()
    }
    
    private func cubeController(){
        switchX = UISwitch(frame: CGRect(x: 20 , y: view.frame.size.height - 100,
                                         width: 100, height: 60))
        switchY = UISwitch(frame: CGRect(x: 10 , y: view.frame.size.height - 100,
                                         width: 100, height: 60))
        switchY.center.x = view.center.x
        switchZ = UISwitch(frame: CGRect(x: view.frame.size.width - 110 , y: view.frame.size.height - 100,
                                         width: 100, height: 60))
        view.addSubview(switchX)
        view.addSubview(switchY)
        view.addSubview(switchZ)
        
        switchX.backgroundColor = .gray
        switchY.backgroundColor = .gray
        switchZ.backgroundColor = .gray
        
        button = UIButton(frame: CGRect(x: 0, y: view.frame.size.height - 160, width: 100, height: 50))
        button.setTitle("旋转", for: UIControl.State.normal)
        button.center.x = view.center.x
        button.backgroundColor = .gray
        button.addTarget(self, action: #selector(rotate(btn:)), for: .touchUpInside)
        view.addSubview(button)
        
        switchX.tag = 101
        switchY.tag = 102
        switchZ.tag = 103
        switchX.addTarget(self, action: #selector(switchAction(switchBtn:)), for: .valueChanged)
        switchY.addTarget(self, action: #selector(switchAction(switchBtn:)), for: .valueChanged)
        switchZ.addTarget(self, action: #selector(switchAction(switchBtn:)), for: .valueChanged)
    }
    
    @objc private func switchAction(switchBtn:UISwitch){
        let tag = switchBtn.tag
        if tag == 101{//X
            cubeImageRender?.positionChange(rotateOn: button.isSelected, type: .x(switchBtn.isOn))
        }else if tag == 102{//Y
            cubeImageRender?.positionChange(rotateOn: button.isSelected, type: .y(switchBtn.isOn))
        }else{//Z
            cubeImageRender?.positionChange(rotateOn: button.isSelected, type: .z(switchBtn.isOn))
        }
    }
    
    @objc private func rotate(btn:UIButton){
        btn.isSelected = !btn.isSelected
        if btn.isSelected {
            btn.setTitle("停止", for: .normal)
        }else {
            btn.setTitle("旋转", for: .normal)
        }
        cubeImageRender?.changeRorate(rotateOn: btn.isSelected)
    }
}
