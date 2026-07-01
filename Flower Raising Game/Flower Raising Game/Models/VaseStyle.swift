import Foundation

struct VaseEffect: Equatable {
    let waterRetention: Double
    let sunlightModifier: Double
    let nutritionEfficiency: Double
    let stressResistance: Double
    let growthModifier: Double
    let summary: String
    let detail: String
}

struct VaseStyle: Identifiable, Equatable {
    let id: String
    let name: String
    let imageName: String
    let frameWidthRatio: Double
    let frameHeightRatio: Double
    let verticalOffsetRatio: Double
    let effect: VaseEffect
}

enum VaseStyleCatalog {
    static let defaultVaseID = "standard"

    static let all: [VaseStyle] = [
        VaseStyle(
            id: defaultVaseID,
            name: "標準の鉢",
            imageName: "tulip_pot",
            frameWidthRatio: 0.60,
            frameHeightRatio: 0.42,
            verticalOffsetRatio: 0.24,
            effect: VaseEffect(
                waterRetention: 1.00,
                sunlightModifier: 1.00,
                nutritionEfficiency: 1.00,
                stressResistance: 1.00,
                growthModifier: 1.00,
                summary: "くせのない標準鉢",
                detail: "水分・日光・栄養に補正がない、扱いやすい鉢です"
            )
        ),
        VaseStyle(
            id: "terracotta",
            name: "テラコッタ",
            imageName: "vase_terracotta",
            frameWidthRatio: 0.49,
            frameHeightRatio: 0.49,
            verticalOffsetRatio: 0.26,
            effect: VaseEffect(
                waterRetention: 0.88,
                sunlightModifier: 1.03,
                nutritionEfficiency: 0.98,
                stressResistance: 1.02,
                growthModifier: 1.03,
                summary: "乾きやすく根が動きやすい",
                detail: "水分は減りやすい代わりに、晴れた日の成長を少し助けます"
            )
        ),
        VaseStyle(
            id: "gray-square",
            name: "石のスクエア",
            imageName: "vase_gray_square",
            frameWidthRatio: 0.52,
            frameHeightRatio: 0.52,
            verticalOffsetRatio: 0.255,
            effect: VaseEffect(
                waterRetention: 1.08,
                sunlightModifier: 0.98,
                nutritionEfficiency: 1.00,
                stressResistance: 1.10,
                growthModifier: 0.98,
                summary: "温度変化に強い安定鉢",
                detail: "水分が少し残りやすく、ストレスの蓄積を抑えます"
            )
        ),
        VaseStyle(
            id: "blue-gloss",
            name: "青い陶器",
            imageName: "vase_blue_gloss",
            frameWidthRatio: 0.52,
            frameHeightRatio: 0.52,
            verticalOffsetRatio: 0.25,
            effect: VaseEffect(
                waterRetention: 1.15,
                sunlightModifier: 0.96,
                nutritionEfficiency: 1.04,
                stressResistance: 1.05,
                growthModifier: 1.00,
                summary: "水持ちがよく雨に強い",
                detail: "水分を保ちやすく栄養効率も少し上がりますが、日光の伸びは控えめです"
            )
        ),
        VaseStyle(
            id: "sage-ribbed",
            name: "セージグリーン",
            imageName: "vase_sage_ribbed",
            frameWidthRatio: 0.49,
            frameHeightRatio: 0.49,
            verticalOffsetRatio: 0.24,
            effect: VaseEffect(
                waterRetention: 1.04,
                sunlightModifier: 1.02,
                nutritionEfficiency: 1.07,
                stressResistance: 1.04,
                growthModifier: 1.02,
                summary: "栄養がなじみやすい鉢",
                detail: "肥料の効果と日光の伸びを少し助けるバランス型です"
            )
        ),
        VaseStyle(
            id: "cream-stand",
            name: "クリームスタンド",
            imageName: "vase_cream_stand",
            frameWidthRatio: 0.52,
            frameHeightRatio: 0.52,
            verticalOffsetRatio: 0.27,
            effect: VaseEffect(
                waterRetention: 0.96,
                sunlightModifier: 1.09,
                nutritionEfficiency: 1.01,
                stressResistance: 0.98,
                growthModifier: 1.04,
                summary: "光を受けやすいスタンド鉢",
                detail: "ライトや晴れの日の日光が伸びやすく、日差し好きの植物と相性が良い鉢です"
            )
        ),
        VaseStyle(
            id: "black-faceted",
            name: "黒い多面鉢",
            imageName: "vase_black_faceted",
            frameWidthRatio: 0.49,
            frameHeightRatio: 0.49,
            verticalOffsetRatio: 0.25,
            effect: VaseEffect(
                waterRetention: 0.94,
                sunlightModifier: 1.05,
                nutritionEfficiency: 1.10,
                stressResistance: 0.96,
                growthModifier: 1.06,
                summary: "成長を攻める高効率鉢",
                detail: "成長と栄養効率が上がりますが、水分管理とストレスに少し注意が必要です"
            )
        ),
        VaseStyle(
            id: "woven-basket",
            name: "編みかご",
            imageName: "vase_woven_basket",
            frameWidthRatio: 0.50,
            frameHeightRatio: 0.50,
            verticalOffsetRatio: 0.25,
            effect: VaseEffect(
                waterRetention: 0.90,
                sunlightModifier: 1.00,
                nutritionEfficiency: 0.96,
                stressResistance: 1.14,
                growthModifier: 0.99,
                summary: "風通しがよく蒸れにくい",
                detail: "水分は抜けやすい代わりに、湿度や水分過多のストレスを抑えます"
            )
        )
    ]

    static func vase(for id: String?) -> VaseStyle {
        all.first { $0.id == id } ?? all[0]
    }
}
