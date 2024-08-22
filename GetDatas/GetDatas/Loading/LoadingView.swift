import SwiftUI

struct LoadingView: View {
    @State private var isActive = false
    
    var body: some View {
        VStack {
            if isActive {
                CarouselView()
            } else {
                VStack {
                    Spacer()
                    Text("raem")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.deepNavy)
                    Spacer()
                }
                .background(
                    GeometryReader { geometry in
                        Color.white
                            .frame(width: geometry.size.width) // 가로로 100% 채우기
                    }
                )
                .edgesIgnoringSafeArea(.all)
                .onAppear {
                    // 2초 후에 CarouselView로 이동
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.isActive = true
                    }
                }
            }
        }
    }
}

struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingView()
    }
}
