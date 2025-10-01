//
//  MinimalTestView.swift
//  ToDoPro
//
//  Created by Youran Tao Jensen on 01/10/2025.
//

import SwiftUI

struct MinimalTestView: View {
    @State private var inputText = ""

    var body: some View {
        VStack(spacing: 30) {
            Text("最小测试版本")
                .font(.title)

            TextField("输入中文测试", text: $inputText)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)

            Text("输入内容: \(inputText)")
                .foregroundColor(.blue)

            Button("清空") {
                inputText = ""
            }
            .padding()
            .background(.red)
            .foregroundColor(.white)
            .cornerRadius(8)

            Spacer()
        }
        .padding()
    }
}

#Preview {
    MinimalTestView()
}