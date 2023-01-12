import SwiftUI

/**
 A SwiftUI view that arranges its children in an interactive deck of cards.
 */
public struct CardStack<Data, Content>: View where Data: RandomAccessCollection, Data.Element: Identifiable, Content: View {
    @State private var currentIndex: Double = 0
    @State private var previousIndex: Double = 0
    
    private let data: Data
    private let swipeDistance: Double
    @Binding var finalCurrentIndex: Int
    @ViewBuilder private let content: (Data.Element) -> Content
    
    
    /// Creates a stack with the given content
    /// - Parameters:
    ///   - data: The identifiable data for computing the list.
    ///   - currentIndex: The index of the topmost card in the stack
    ///   - swipeDistance: The travel distance required to transition to the previous or next element
    ///   - content: A view builder that creates the view for a single card
    public init(_ data: Data,
                currentIndex: Binding<Int> = .constant(0),
                swipeDistance: Double = 300,
                @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = data
        self._finalCurrentIndex = currentIndex
        self.swipeDistance = swipeDistance
        self.content = content
    }
    
    public var body: some View {
        ZStack {
            ForEach(Array(data.enumerated()), id: \.element.id) { (index, element) in
                content(element)
                    .zIndex(zIndex(for: index))
                    .offset(x: xOffset(for: index), y: 0)
                    .scaleEffect(scale(for: index), anchor: .center)
                    .rotationEffect(.degrees(rotationDegrees(for: index)))
            }
        }
        .highPriorityGesture(dragGesture)
    }
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                withAnimation(.interactiveSpring()) {
                    let diff = value.translation.width / swipeDistance
                    self.currentIndex = previousIndex - diff
                }
            }
            .onEnded { value in
                self.snapToNearestAbsoluteIndex()
                self.previousIndex = self.currentIndex
            }
    }
    
    private func snapToNearestAbsoluteIndex() {
        withAnimation(.interpolatingSpring(stiffness: 500, damping: 40)) { // TODO: Extract the stiffness and damping
            self.updateIndices()
        }
    }
    
    private func updateIndices() {
        var index = round(self.currentIndex)
        let maxIndex = Double(self.data.count - 1)
        if index < 0 {
            index = 0
        } else if index > maxIndex {
            index = maxIndex
        }
        self.currentIndex = index
        self.finalCurrentIndex = Int(index)
    }
    
    private func zIndex(for index: Int) -> Double {
        if (Double(index) + 0.5) < currentIndex {
            return -Double(data.count - index)
        } else {
            return Double(data.count - index)
        }
    }
    
    private func xOffset(for index: Int) -> CGFloat {
        let topCardProgress = currentPosition(for: index)
        let padding = 35.0
        let x = ((CGFloat(index) - currentIndex) * padding)
        if topCardProgress > 0 && topCardProgress < 0.99 && index < (data.count - 1) {
            return x * swingOutMultiplier(topCardProgress)
        }
        return x
    }
    
    private func scale(for index: Int) -> CGFloat {
        return 1.0 - (0.1 * abs(currentPosition(for: index)))
    }
    
    private func rotationDegrees(for index: Int) -> Double {
        return -currentPosition(for: index) * 2
    }
    
    private func currentPosition(for index: Int) -> Double {
        self.currentIndex - Double(index)
    }
    
    private func swingOutMultiplier(_ progress: Double) -> Double {
        return sin(Double.pi * progress) * 15
    }
}

struct CardStackView_Previews: PreviewProvider {
    
    struct DemoItem: Identifiable {
        let name: String
        let color: Color
        
        var id: String {
            name
        }
    }
    
    struct DemoView: View {
        @State private var currentIndex = 0
        @State private var tappedIndex: Int? = nil
        
        var body: some View {
            let colors = [
                DemoItem(name: "Red", color: .red),
                DemoItem(name: "Orange", color: .orange),
                DemoItem(name: "Yellow", color: .yellow),
                DemoItem(name: "Green", color: .green),
                DemoItem(name: "Blue", color: .blue),
                DemoItem(name: "Purple", color: .purple),
            ]
            
            VStack {
                CardStack(colors, currentIndex: $currentIndex) { namedColor in
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(namedColor.color)
                        .overlay(
                            Text(namedColor.name)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        )
                        .frame(height: 400)
                        .onTapGesture {
                            tappedIndex = currentIndex
                        }
                        .padding(50)

                }
                
                Text("Current card is \(currentIndex)")
                if let tappedIndex = tappedIndex {
                    Text("Card \(tappedIndex) was tapped")
                } else {
                    Text("No card has been tapped")
                }
            }
        }
    }
    
    static var previews: some View {
        DemoView()
    }

}
