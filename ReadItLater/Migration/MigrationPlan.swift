//
//  MigrationPlan.swift
//  ReadItLater
//
//  Created by 宗像恒 on 2025/08/02.
//
import SwiftData

struct AppMigrationPlan: SchemaMigrationPlan {
    static let schemas: [VersionedSchema.Type] = [
        AppV1Schema.self,
        AppV2Schema.self
    ]
    static let stages: [MigrationStage] = []
}
