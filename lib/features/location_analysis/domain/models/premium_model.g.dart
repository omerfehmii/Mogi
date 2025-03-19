// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'premium_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PremiumModelAdapter extends TypeAdapter<PremiumModel> {
  @override
  final int typeId = 4;

  @override
  PremiumModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PremiumModel(
      isPremium: fields[0] as bool,
      premiumUntil: fields[1] as DateTime?,
      freeAiChatsRemaining: fields[2] as int,
      freeLocationAnalysisRemaining: fields[3] as int,
      coins: fields[4] as int,
      subscriptionType: fields[5] as String?,
      referralCode: fields[6] as String?,
      premiumFeatureAccess: (fields[7] as Map?)?.cast<String, bool>(),
      usageStatistics: (fields[8] as Map?)?.cast<String, dynamic>(),
      purchaseHistory: (fields[9] as List?)
          ?.map((dynamic e) => (e as Map).cast<String, dynamic>())
          ?.toList(),
      discountPercentage: fields[10] as int,
      discountExpiryDate: fields[11] as DateTime?,
      lastSyncedAt: fields[12] as DateTime?,
      serverVerificationToken: fields[13] as String?,
      securityMetadata: (fields[14] as Map?)?.cast<String, dynamic>(),
      subscriptionEndDate: fields[15] as DateTime?,
      mogiPoints: fields[16] as int,
      coinUsageHistory: (fields[17] as List)
          .map((dynamic e) => (e as Map).cast<String, dynamic>())
          .toList(),
      coinAdditionHistory: (fields[18] as List)
          .map((dynamic e) => (e as Map).cast<String, dynamic>())
          .toList(),
      transactionHistory: (fields[19] as List?)
          ?.map((dynamic e) => (e as Map).cast<String, dynamic>())
          ?.toList(),
      deviceFingerprint: fields[20] as String?,
      lastModified: fields[21] as DateTime?,
      securityHashes: (fields[22] as Map?)?.cast<String, String>(),
    );
  }

  @override
  void write(BinaryWriter writer, PremiumModel obj) {
    writer
      ..writeByte(23)
      ..writeByte(0)
      ..write(obj.isPremium)
      ..writeByte(1)
      ..write(obj.premiumUntil)
      ..writeByte(2)
      ..write(obj.freeAiChatsRemaining)
      ..writeByte(3)
      ..write(obj.freeLocationAnalysisRemaining)
      ..writeByte(4)
      ..write(obj.coins)
      ..writeByte(5)
      ..write(obj.subscriptionType)
      ..writeByte(6)
      ..write(obj.referralCode)
      ..writeByte(7)
      ..write(obj.premiumFeatureAccess)
      ..writeByte(8)
      ..write(obj.usageStatistics)
      ..writeByte(9)
      ..write(obj.purchaseHistory)
      ..writeByte(10)
      ..write(obj.discountPercentage)
      ..writeByte(11)
      ..write(obj.discountExpiryDate)
      ..writeByte(12)
      ..write(obj.lastSyncedAt)
      ..writeByte(13)
      ..write(obj.serverVerificationToken)
      ..writeByte(14)
      ..write(obj.securityMetadata)
      ..writeByte(15)
      ..write(obj.subscriptionEndDate)
      ..writeByte(16)
      ..write(obj.mogiPoints)
      ..writeByte(17)
      ..write(obj.coinUsageHistory)
      ..writeByte(18)
      ..write(obj.coinAdditionHistory)
      ..writeByte(19)
      ..write(obj.transactionHistory)
      ..writeByte(20)
      ..write(obj.deviceFingerprint)
      ..writeByte(21)
      ..write(obj.lastModified)
      ..writeByte(22)
      ..write(obj.securityHashes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PremiumModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
