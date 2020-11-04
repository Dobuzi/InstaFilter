//
//  ContentView.swift
//  InstaFilter
//
//  Created by 김종원 on 2020/11/01.
//

import SwiftUI

import CoreImage
import CoreImage.CIFilterBuiltins

struct ContentView: View {
    @State private var image: Image?
    @State private var inputImage: UIImage?
    @State private var processedImage: UIImage?
    
    @State private var showingImagePicker = false
    @State private var showingFilterSheet = false
    @State private var showingSaveAlert = false
    
    @State private var currentFilter: CIFilter = CIFilter.sepiaTone()
    @State private var currentFilterName: String = "Sepia Tone"
    
    @State private var filterIntensity = 0.5
    @State private var filterRadius = 100.0
    
    @State private var showIntensitySlider = false
    @State private var showRadiusSlider = false
    
    let context = CIContext()
    
    var body: some View {
        let intensity = Binding<Double>(
            get: {
                self.filterIntensity
            }, set: {
                self.filterIntensity = $0
                self.applyProcessing()
            }
        )
        let radius = Binding<Double>(get: {
            self.filterRadius
        }, set: {
            self.filterRadius = $0
            self.applyProcessing()
        })
        
        return NavigationView {
            VStack {
                ZStack {
                    Rectangle()
                        .fill(Color.blue.opacity(image != nil ? 0 : 0.5))
                    
                    if let image = image {
                        image
                            .resizable()
                            .scaledToFit()
                    } else {
                        Text("Tap to select a picture")
                            .foregroundColor(.white)
                            .font(.title3)
                    }
                }
                .cornerRadius(50)
                .shadow(radius: 10)
                .onTapGesture(count: 1, perform: {
                    self.showingImagePicker = true
                })
                VStack {
                    if showIntensitySlider {
                        HStack {
                            Text("Intensity")
                            Slider(value: intensity)
                        }
                    }
                    if showRadiusSlider {
                        HStack {
                            Text("Radius")
                            Slider(value: radius, in: 0...200)
                        }
                    }
                }
                .frame(height: 100)
                .padding(.vertical)
                HStack {
                    Button(currentFilterName) {
                        self.showingFilterSheet = true
                    }
                    .disabled(self.image == nil)
                    
                    Spacer()
                    
                    Button("Save") {
                        guard let processedImage = self.processedImage else { return }
                        
                        let imageSaver = ImageSaver()
                        
                        imageSaver.successHandler = {
                            print("Success!")
                        }
                        
                        imageSaver.errorHandler = {
                            print("Oops: \($0.localizedDescription)")
                        }
                        
                        imageSaver.writeToPhotoAlbum(image: processedImage)
                        
                        self.showingSaveAlert = true
                    }
                    .disabled(self.image == nil)
                }
            }
            .padding([.horizontal, .bottom])
            .navigationBarTitle("Insta Filter")
            .sheet(isPresented: $showingImagePicker, onDismiss: loadImage) {
                ImagePicker(image: self.$inputImage)
            }
            .actionSheet(isPresented: $showingFilterSheet) {
                ActionSheet(title: Text("Select a filter"), buttons: [
                    .default(Text("Crystallize")) {
                        self.currentFilterName = "Crystallize"
                        self.setFilter(.crystallize())
                    },
                    .default(Text("Edges")) {
                        self.currentFilterName = "Edges"
                        self.setFilter(.edges())
                    },
                    .default(Text("Gaussian Blur")) {
                        self.currentFilterName = "Gaussian Blur"
                        self.setFilter(.gaussianBlur())
                    },
                    .default(Text("Pixellate")) {
                        self.currentFilterName = "Pixellate"
                        self.setFilter(.pixellate())
                    },
                    .default(Text("Sepia Tone")) {
                        self.currentFilterName = "Sepia Tone"
                        self.setFilter(.sepiaTone())
                    },
                    .default(Text("Unsharp Mask")) {
                        self.currentFilterName = "Unsharp Mask"
                        self.setFilter(.unsharpMask())
                    },
                    .default(Text("Vignette")) {
                        self.currentFilterName = "Vignette"
                        self.setFilter(.vignette())
                    },
                    .cancel()
                ])
            }
            .alert(isPresented: $showingSaveAlert) {
                Alert(title: Text("Image is saved"), message: Text("Check your photo album."), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    func loadImage() {
        guard let inputImage = inputImage else { return }
        let beginImage = CIImage(image: inputImage)
        currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
        applyProcessing()
    }
    
    func applyProcessing() {
        let inputKeys = currentFilter.inputKeys
        if inputKeys.contains(kCIInputIntensityKey) {
            showIntensitySlider = true
            currentFilter.setValue(filterIntensity, forKey: kCIInputIntensityKey)
        } else if inputKeys.contains(kCIInputScaleKey) {
            showIntensitySlider = true
            currentFilter.setValue(filterIntensity * 10, forKey: kCIInputScaleKey)
        } else {
            showIntensitySlider = false
        }
        if inputKeys.contains(kCIInputRadiusKey) {
            showRadiusSlider = true
            currentFilter.setValue(filterRadius, forKey: kCIInputRadiusKey)
        } else {
            showRadiusSlider = false
        }
        
        
        
        guard let outputImage = currentFilter.outputImage else { return }
        
        if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
            processedImage = UIImage(cgImage: cgimg)
            if let uiImage = processedImage {
                image = Image(uiImage: uiImage)
            }
        }
    }
    
    func setFilter(_ filter: CIFilter) {
        currentFilter = filter
        loadImage()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
