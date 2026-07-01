import Foundation

enum PlantCareAffinity {
    case water
    case sunlight
    case fertilizer
}

struct PlantPreference: Equatable {
    let idealWater: ClosedRange<Double>
    let viableWater: ClosedRange<Double>
    let idealSunlight: ClosedRange<Double>
    let viableSunlight: ClosedRange<Double>
    let idealNutrition: ClosedRange<Double>
    let viableNutrition: ClosedRange<Double>
    let idealMood: ClosedRange<Double>
    let viableMood: ClosedRange<Double>
    let preferredWeather: Set<WeatherType>
    let weakWeather: Set<WeatherType>
    let careAffinity: PlantCareAffinity
    let growthBias: Double
    let summary: String
    let careHint: String
}

struct PlantSpecies: Identifiable, Equatable {
    let id: String
    let name: String
    let seedImageName: String
    let normalStageImageNames: [String]
    let wiltedStageImageNames: [String]
    let deadStageImageNames: [String]?
    let preference: PlantPreference

    func imageName(
        for stageNumber: Int,
        isWilted: Bool,
        isDead: Bool
    ) -> String {
        if isDead {
            if let deadStageImageNames {
                let deadIndexBase = deadStageImageNames.count >= normalStageImageNames.count ? stageNumber - 1 : stageNumber - 2
                let deadIndex = min(max(deadIndexBase, 0), deadStageImageNames.count - 1)
                return deadStageImageNames[deadIndex]
            }

            guard stageNumber > 1 else {
                return normalStageImageNames[0]
            }

            let deadStageNumber = stageNumber == 4 ? 3 : stageNumber
            return String(format: "dead_stage_%02d", deadStageNumber)
        }

        if isWilted {
            let wiltedIndexBase = wiltedStageImageNames.count >= normalStageImageNames.count ? stageNumber - 1 : stageNumber - 2
            let wiltedIndex = min(max(wiltedIndexBase, 0), wiltedStageImageNames.count - 1)
            return wiltedStageImageNames[wiltedIndex]
        }

        let normalIndex = min(max(stageNumber - 1, 0), normalStageImageNames.count - 1)
        return normalStageImageNames[normalIndex]
    }
}

enum PlantSpeciesCatalog {
    static let defaultPlantID = "tulip"

    static let all: [PlantSpecies] = [
        PlantSpecies(
            id: defaultPlantID,
            name: "チューリップ",
            seedImageName: "ChatGPT Image 2026年5月15日 12_33_35",
            normalStageImageNames: [
                "ChatGPT Image 2026年5月15日 12_33_35",
                "growth_stage_02",
                "growth_stage_03",
                "growth_stage_04",
                "growth_stage_05",
                "growth_stage_06",
                "growth_stage_07",
                "growth_stage_08",
                "growth_stage_09",
                "growth_stage_10"
            ],
            wiltedStageImageNames: [
                "wilted_stage_02",
                "wilted_stage_03",
                "wilted_stage_04",
                "wilted_stage_05",
                "wilted_stage_06",
                "wilted_stage_07",
                "wilted_stage_08",
                "wilted_stage_09",
                "wilted_stage_10"
            ],
            deadStageImageNames: nil,
            preference: PlantPreference(
                idealWater: 56...84,
                viableWater: 34...95,
                idealSunlight: 58...88,
                viableSunlight: 38...96,
                idealNutrition: 54...84,
                viableNutrition: 36...95,
                idealMood: 66...100,
                viableMood: 44...100,
                preferredWeather: [.sunny, .cloudy],
                weakWeather: [.stormy],
                careAffinity: .sunlight,
                growthBias: 1.00,
                summary: "日なたとほどよい水分が好き",
                careHint: "日光58%以上、水分は多すぎない範囲を保つと安定します"
            )
        ),
        PlantSpecies(
            id: "sunflower",
            name: "ひまわり",
            seedImageName: "ChatGPT Image 2026年6月2日 16_20_33 (1)",
            normalStageImageNames: [
                "ChatGPT Image 2026年6月2日 16_20_33 (1)",
                "ChatGPT Image 2026年6月2日 16_20_33 (2)",
                "ChatGPT Image 2026年6月2日 16_20_33 (3)",
                "ChatGPT Image 2026年6月2日 16_20_33 (4)",
                "ChatGPT Image 2026年6月2日 16_20_34 (5)",
                "ChatGPT Image 2026年6月2日 16_20_34 (6)",
                "ChatGPT Image 2026年6月2日 16_20_34 (7)",
                "ChatGPT Image 2026年6月2日 16_20_35 (8)",
                "ChatGPT Image 2026年6月2日 16_20_35 (9)",
                "ChatGPT Image 2026年6月2日 16_20_35 (10)"
            ],
            wiltedStageImageNames: [
                "ChatGPT Image 2026年6月2日 16_26_16 (1)",
                "ChatGPT Image 2026年6月2日 16_26_16 (2)",
                "ChatGPT Image 2026年6月2日 16_26_17 (3)",
                "ChatGPT Image 2026年6月2日 16_26_17 (4)",
                "ChatGPT Image 2026年6月2日 16_26_17 (5)",
                "ChatGPT Image 2026年6月2日 16_26_18 (6)",
                "ChatGPT Image 2026年6月2日 16_26_18 (7)",
                "ChatGPT Image 2026年6月2日 16_26_19 (8)",
                "ChatGPT Image 2026年6月2日 16_26_19 (9)"
            ],
            deadStageImageNames: [
                "ChatGPT Image 2026年6月2日 16_47_12 (1)",
                "ChatGPT Image 2026年6月2日 16_47_12 (2)",
                "ChatGPT Image 2026年6月2日 16_47_13 (3)",
                "ChatGPT Image 2026年6月2日 16_47_13 (4)",
                "ChatGPT Image 2026年6月2日 16_47_14 (5)",
                "ChatGPT Image 2026年6月2日 16_47_14 (6)",
                "ChatGPT Image 2026年6月2日 16_47_15 (7)",
                "ChatGPT Image 2026年6月2日 16_47_16 (8)",
                "ChatGPT Image 2026年6月2日 16_47_17 (9)"
            ],
            preference: PlantPreference(
                idealWater: 50...76,
                viableWater: 28...90,
                idealSunlight: 72...96,
                viableSunlight: 48...100,
                idealNutrition: 60...88,
                viableNutrition: 38...96,
                idealMood: 62...100,
                viableMood: 42...100,
                preferredWeather: [.sunny],
                weakWeather: [.rainy, .stormy],
                careAffinity: .sunlight,
                growthBias: 1.08,
                summary: "強い日差しと栄養が好き",
                careHint: "日光72%以上が理想。雨や嵐の日はライトで補うと育ちやすいです"
            )
        ),
        PlantSpecies(
            id: "morning-glory",
            name: "朝顔",
            seedImageName: "ChatGPT Image 2026年6月2日 16_57_23 (1)",
            normalStageImageNames: [
                "ChatGPT Image 2026年6月2日 16_57_23 (1)",
                "ChatGPT Image 2026年6月2日 16_57_23 (2)",
                "ChatGPT Image 2026年6月2日 16_57_24 (3)",
                "ChatGPT Image 2026年6月2日 16_57_25 (4)",
                "ChatGPT Image 2026年6月2日 16_57_25 (5)",
                "ChatGPT Image 2026年6月2日 16_57_26 (6)",
                "ChatGPT Image 2026年6月2日 16_57_26 (7)",
                "ChatGPT Image 2026年6月2日 16_57_27 (8)",
                "ChatGPT Image 2026年6月2日 16_57_27 (9)",
                "ChatGPT Image 2026年6月2日 16_57_28 (10)"
            ],
            wiltedStageImageNames: [
                "ChatGPT Image 2026年6月2日 16_57_23 (2)",
                "ChatGPT Image 2026年6月2日 17_07_39 (2)",
                "ChatGPT Image 2026年6月2日 17_07_39 (3)",
                "ChatGPT Image 2026年6月2日 17_07_40 (4)",
                "ChatGPT Image 2026年6月2日 17_07_40 (5)",
                "ChatGPT Image 2026年6月2日 17_07_41 (6)",
                "ChatGPT Image 2026年6月2日 17_07_41 (7)",
                "ChatGPT Image 2026年6月2日 17_07_42 (8)",
                "ChatGPT Image 2026年6月2日 17_07_43 (9)"
            ],
            deadStageImageNames: [
                "ChatGPT Image 2026年6月2日 16_57_23 (2)",
                "ChatGPT Image 2026年6月2日 17_12_08 (2)",
                "ChatGPT Image 2026年6月2日 17_12_08 (3)",
                "ChatGPT Image 2026年6月2日 17_12_08 (4)",
                "ChatGPT Image 2026年6月2日 17_12_09 (5)",
                "ChatGPT Image 2026年6月2日 17_12_09 (6)",
                "ChatGPT Image 2026年6月2日 17_12_10 (7)",
                "ChatGPT Image 2026年6月2日 17_12_10 (8)",
                "ChatGPT Image 2026年6月2日 17_12_11 (9)"
            ],
            preference: PlantPreference(
                idealWater: 64...90,
                viableWater: 42...98,
                idealSunlight: 52...82,
                viableSunlight: 34...94,
                idealNutrition: 48...78,
                viableNutrition: 34...92,
                idealMood: 68...100,
                viableMood: 46...100,
                preferredWeather: [.cloudy, .rainy],
                weakWeather: [.windy, .stormy],
                careAffinity: .water,
                growthBias: 0.96,
                summary: "朝の水分とやわらかい光が好き",
                careHint: "水分64%以上が理想。強風の日は乾きすぎに注意しましょう"
            )
        ),
        PlantSpecies(
            id: "rose",
            name: "バラ",
            seedImageName: "ChatGPT Image 2026年6月13日 01_08_04",
            normalStageImageNames: [
                "ChatGPT Image 2026年6月13日 01_08_04",
                "ChatGPT Image 2026年6月13日 01_46_14",
                "ChatGPT Image 2026年6月13日 00_58_38 (3)",
                "ChatGPT Image 2026年6月13日 00_58_38 (4)",
                "ChatGPT Image 2026年6月13日 00_58_38 (5)",
                "ChatGPT Image 2026年6月13日 00_58_39 (6)",
                "ChatGPT Image 2026年6月13日 00_58_39 (7)",
                "ChatGPT Image 2026年6月13日 00_58_39 (8)",
                "ChatGPT Image 2026年6月13日 00_58_39 (9)",
                "ChatGPT Image 2026年6月13日 00_58_40 (10)"
            ],
            wiltedStageImageNames: [
                "ChatGPT Image 2026年6月13日 01_46_14",
                "ChatGPT Image 2026年7月1日 17_03_05 (1)",
                "ChatGPT Image 2026年7月1日 17_03_05 (2)",
                "ChatGPT Image 2026年7月1日 17_03_05 (3)",
                "ChatGPT Image 2026年7月1日 17_03_05 (4)",
                "ChatGPT Image 2026年7月1日 17_03_06 (5)",
                "ChatGPT Image 2026年7月1日 17_03_06 (6)",
                "ChatGPT Image 2026年7月1日 17_03_06 (7)",
                "ChatGPT Image 2026年7月1日 17_03_06 (8)"
            ],
            deadStageImageNames: [
                "ChatGPT Image 2026年6月13日 01_46_14",
                "ChatGPT Image 2026年7月1日 17_12_44",
                "ChatGPT Image 2026年7月1日 17_12_40",
                "ChatGPT Image 2026年7月1日 17_12_35",
                "ChatGPT Image 2026年7月1日 17_12_31",
                "ChatGPT Image 2026年7月1日 17_12_26",
                "ChatGPT Image 2026年7月1日 17_12_22",
                "ChatGPT Image 2026年7月1日 17_11_54 (7)",
                "ChatGPT Image 2026年7月1日 17_11_54 (8)"
            ],
            preference: PlantPreference(
                idealWater: 48...74,
                viableWater: 30...88,
                idealSunlight: 62...88,
                viableSunlight: 40...96,
                idealNutrition: 58...88,
                viableNutrition: 38...96,
                idealMood: 66...100,
                viableMood: 44...100,
                preferredWeather: [.sunny, .cloudy],
                weakWeather: [.stormy],
                careAffinity: .fertilizer,
                growthBias: 1.02,
                summary: "日当たりと栄養が好き",
                careHint: "日光62%以上と栄養58%以上を保つと花つきが安定します"
            )
        ),
        PlantSpecies(
            id: "cactus",
            name: "サボテン",
            seedImageName: "ChatGPT Image 2026年6月13日 02_56_42 (1)",
            normalStageImageNames: [
                "ChatGPT Image 2026年6月13日 02_56_42 (1)",
                "ChatGPT Image 2026年6月13日 02_56_42 (2)",
                "ChatGPT Image 2026年6月13日 02_56_43 (5)",
                "ChatGPT Image 2026年6月13日 02_56_43 (4)",
                "ChatGPT Image 2026年6月13日 02_56_43 (3)",
                "ChatGPT Image 2026年6月13日 02_56_43 (6)",
                "ChatGPT Image 2026年6月13日 02_56_44 (8)",
                "ChatGPT Image 2026年6月13日 02_56_44 (7)",
                "ChatGPT Image 2026年6月13日 02_56_44 (9)",
                "ChatGPT Image 2026年6月13日 02_56_44 (10)"
            ],
            wiltedStageImageNames: [
                "ChatGPT Image 2026年7月1日 18_05_23 (1)",
                "ChatGPT Image 2026年7月1日 18_05_23 (2)",
                "ChatGPT Image 2026年7月1日 18_05_24 (5)",
                "ChatGPT Image 2026年7月1日 18_05_24 (4)",
                "ChatGPT Image 2026年7月1日 18_05_24 (6)",
                "ChatGPT Image 2026年7月1日 18_05_23 (3)",
                "ChatGPT Image 2026年7月1日 18_05_25 (8)",
                "ChatGPT Image 2026年7月1日 18_05_25 (7)",
                "ChatGPT Image 2026年7月1日 18_05_26 (9)",
                "ChatGPT Image 2026年7月1日 18_05_26 (10)"
            ],
            deadStageImageNames: [
                "ChatGPT Image 2026年7月1日 18_09_12 (1)",
                "ChatGPT Image 2026年7月1日 18_09_12 (2)",
                "ChatGPT Image 2026年7月1日 18_09_14 (5)",
                "ChatGPT Image 2026年7月1日 18_09_13 (4)",
                "ChatGPT Image 2026年7月1日 18_09_14 (6)",
                "ChatGPT Image 2026年7月1日 18_09_13 (3)",
                "ChatGPT Image 2026年7月1日 18_09_15 (8)",
                "ChatGPT Image 2026年7月1日 18_09_14 (7)",
                "ChatGPT Image 2026年7月1日 18_09_15 (9)",
                "ChatGPT Image 2026年7月1日 18_09_16 (10)"
            ],
            preference: PlantPreference(
                idealWater: 22...48,
                viableWater: 10...66,
                idealSunlight: 68...96,
                viableSunlight: 44...100,
                idealNutrition: 38...68,
                viableNutrition: 20...86,
                idealMood: 62...100,
                viableMood: 40...100,
                preferredWeather: [.sunny, .windy],
                weakWeather: [.rainy, .stormy],
                careAffinity: .sunlight,
                growthBias: 0.94,
                summary: "乾き気味と強い日差しが好き",
                careHint: "水分は控えめ、日光68%以上を保つとゆっくり安定して育ちます"
            )
        ),
        PlantSpecies(
            id: "dahlia",
            name: "ダリア",
            seedImageName: "ChatGPT Image 2026年6月13日 14_08_22 (1)",
            normalStageImageNames: [
                "ChatGPT Image 2026年6月13日 14_08_22 (1)",
                "ChatGPT Image 2026年6月13日 14_09_32",
                "ChatGPT Image 2026年6月13日 14_09_38",
                "ChatGPT Image 2026年6月13日 14_08_22 (4)",
                "ChatGPT Image 2026年6月13日 14_08_22 (5)",
                "ChatGPT Image 2026年6月13日 14_08_23 (6)",
                "ChatGPT Image 2026年6月13日 14_08_23 (7)",
                "ChatGPT Image 2026年6月13日 14_08_11 (8)",
                "ChatGPT Image 2026年6月13日 14_08_24 (9)",
                "ChatGPT Image 2026年6月13日 14_08_24 (10)"
            ],
            wiltedStageImageNames: [
                "ChatGPT Image 2026年7月1日 18_20_25 (2)",
                "ChatGPT Image 2026年7月1日 18_23_39",
                "ChatGPT Image 2026年7月1日 18_20_29 (10)",
                "ChatGPT Image 2026年7月1日 18_20_26 (3)",
                "ChatGPT Image 2026年7月1日 18_20_26 (4)",
                "ChatGPT Image 2026年7月1日 18_20_27 (5)",
                "ChatGPT Image 2026年7月1日 18_20_27 (6)",
                "ChatGPT Image 2026年7月1日 18_20_25 (1)",
                "ChatGPT Image 2026年7月1日 18_20_28 (7)",
                "ChatGPT Image 2026年7月1日 18_23_34"
            ],
            deadStageImageNames: [
                "ChatGPT Image 2026年7月1日 18_28_43 (2)",
                "ChatGPT Image 2026年7月1日 18_28_48 (9)",
                "ChatGPT Image 2026年7月1日 18_28_48 (10)",
                "ChatGPT Image 2026年7月1日 18_28_44 (3)",
                "ChatGPT Image 2026年7月1日 18_28_44 (4)",
                "ChatGPT Image 2026年7月1日 18_28_46 (5)",
                "ChatGPT Image 2026年7月1日 18_28_46 (6)",
                "ChatGPT Image 2026年7月1日 18_28_43 (1)",
                "ChatGPT Image 2026年7月1日 18_28_47 (7)",
                "ChatGPT Image 2026年7月1日 18_28_47 (8)"
            ],
            preference: PlantPreference(
                idealWater: 50...78,
                viableWater: 30...92,
                idealSunlight: 60...88,
                viableSunlight: 40...96,
                idealNutrition: 60...90,
                viableNutrition: 38...98,
                idealMood: 66...100,
                viableMood: 44...100,
                preferredWeather: [.sunny, .cloudy],
                weakWeather: [.stormy],
                careAffinity: .fertilizer,
                growthBias: 1.00,
                summary: "日当たりと栄養が好き",
                careHint: "日光60%以上と栄養60%以上を保つと大きな花が安定します"
            )
        )
    ]

    static func plant(for id: String?) -> PlantSpecies {
        all.first { $0.id == id } ?? all[0]
    }
}
