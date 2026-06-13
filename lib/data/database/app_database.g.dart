// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AnnotationsTable extends Annotations
    with TableInfo<$AnnotationsTable, Annotation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AnnotationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => Uuid().v4(),
  );
  static const VerificationMeta _fileIdMeta = const VerificationMeta('fileId');
  @override
  late final GeneratedColumn<String> fileId = GeneratedColumn<String>(
    'file_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pageIndexMeta = const VerificationMeta(
    'pageIndex',
  );
  @override
  late final GeneratedColumn<int> pageIndex = GeneratedColumn<int>(
    'page_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<int> type = GeneratedColumn<int>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
    'data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _boundsLeftMeta = const VerificationMeta(
    'boundsLeft',
  );
  @override
  late final GeneratedColumn<double> boundsLeft = GeneratedColumn<double>(
    'bounds_left',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _boundsTopMeta = const VerificationMeta(
    'boundsTop',
  );
  @override
  late final GeneratedColumn<double> boundsTop = GeneratedColumn<double>(
    'bounds_top',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _boundsRightMeta = const VerificationMeta(
    'boundsRight',
  );
  @override
  late final GeneratedColumn<double> boundsRight = GeneratedColumn<double>(
    'bounds_right',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _boundsBottomMeta = const VerificationMeta(
    'boundsBottom',
  );
  @override
  late final GeneratedColumn<double> boundsBottom = GeneratedColumn<double>(
    'bounds_bottom',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    fileId,
    pageIndex,
    type,
    data,
    boundsLeft,
    boundsTop,
    boundsRight,
    boundsBottom,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'annotations';
  @override
  VerificationContext validateIntegrity(
    Insertable<Annotation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('file_id')) {
      context.handle(
        _fileIdMeta,
        fileId.isAcceptableOrUnknown(data['file_id']!, _fileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_fileIdMeta);
    }
    if (data.containsKey('page_index')) {
      context.handle(
        _pageIndexMeta,
        pageIndex.isAcceptableOrUnknown(data['page_index']!, _pageIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_pageIndexMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
        _dataMeta,
        this.data.isAcceptableOrUnknown(data['data']!, _dataMeta),
      );
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    if (data.containsKey('bounds_left')) {
      context.handle(
        _boundsLeftMeta,
        boundsLeft.isAcceptableOrUnknown(data['bounds_left']!, _boundsLeftMeta),
      );
    } else if (isInserting) {
      context.missing(_boundsLeftMeta);
    }
    if (data.containsKey('bounds_top')) {
      context.handle(
        _boundsTopMeta,
        boundsTop.isAcceptableOrUnknown(data['bounds_top']!, _boundsTopMeta),
      );
    } else if (isInserting) {
      context.missing(_boundsTopMeta);
    }
    if (data.containsKey('bounds_right')) {
      context.handle(
        _boundsRightMeta,
        boundsRight.isAcceptableOrUnknown(
          data['bounds_right']!,
          _boundsRightMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_boundsRightMeta);
    }
    if (data.containsKey('bounds_bottom')) {
      context.handle(
        _boundsBottomMeta,
        boundsBottom.isAcceptableOrUnknown(
          data['bounds_bottom']!,
          _boundsBottomMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_boundsBottomMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Annotation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Annotation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      fileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_id'],
      )!,
      pageIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page_index'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}type'],
      )!,
      data: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data'],
      )!,
      boundsLeft: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}bounds_left'],
      )!,
      boundsTop: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}bounds_top'],
      )!,
      boundsRight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}bounds_right'],
      )!,
      boundsBottom: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}bounds_bottom'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AnnotationsTable createAlias(String alias) {
    return $AnnotationsTable(attachedDatabase, alias);
  }
}

class Annotation extends DataClass implements Insertable<Annotation> {
  final String id;
  final String fileId;
  final int pageIndex;

  /// Type of annotation: 0=stroke, 1=text, 2=shape, 3=highlight
  final int type;

  /// JSON encoded data (points for strokes, text content for text, etc.)
  final String data;

  /// Bounding box for spatial queries (stored as L,T,R,B for easy querying)
  final double boundsLeft;
  final double boundsTop;
  final double boundsRight;
  final double boundsBottom;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Annotation({
    required this.id,
    required this.fileId,
    required this.pageIndex,
    required this.type,
    required this.data,
    required this.boundsLeft,
    required this.boundsTop,
    required this.boundsRight,
    required this.boundsBottom,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['file_id'] = Variable<String>(fileId);
    map['page_index'] = Variable<int>(pageIndex);
    map['type'] = Variable<int>(type);
    map['data'] = Variable<String>(data);
    map['bounds_left'] = Variable<double>(boundsLeft);
    map['bounds_top'] = Variable<double>(boundsTop);
    map['bounds_right'] = Variable<double>(boundsRight);
    map['bounds_bottom'] = Variable<double>(boundsBottom);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AnnotationsCompanion toCompanion(bool nullToAbsent) {
    return AnnotationsCompanion(
      id: Value(id),
      fileId: Value(fileId),
      pageIndex: Value(pageIndex),
      type: Value(type),
      data: Value(data),
      boundsLeft: Value(boundsLeft),
      boundsTop: Value(boundsTop),
      boundsRight: Value(boundsRight),
      boundsBottom: Value(boundsBottom),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Annotation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Annotation(
      id: serializer.fromJson<String>(json['id']),
      fileId: serializer.fromJson<String>(json['fileId']),
      pageIndex: serializer.fromJson<int>(json['pageIndex']),
      type: serializer.fromJson<int>(json['type']),
      data: serializer.fromJson<String>(json['data']),
      boundsLeft: serializer.fromJson<double>(json['boundsLeft']),
      boundsTop: serializer.fromJson<double>(json['boundsTop']),
      boundsRight: serializer.fromJson<double>(json['boundsRight']),
      boundsBottom: serializer.fromJson<double>(json['boundsBottom']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'fileId': serializer.toJson<String>(fileId),
      'pageIndex': serializer.toJson<int>(pageIndex),
      'type': serializer.toJson<int>(type),
      'data': serializer.toJson<String>(data),
      'boundsLeft': serializer.toJson<double>(boundsLeft),
      'boundsTop': serializer.toJson<double>(boundsTop),
      'boundsRight': serializer.toJson<double>(boundsRight),
      'boundsBottom': serializer.toJson<double>(boundsBottom),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Annotation copyWith({
    String? id,
    String? fileId,
    int? pageIndex,
    int? type,
    String? data,
    double? boundsLeft,
    double? boundsTop,
    double? boundsRight,
    double? boundsBottom,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Annotation(
    id: id ?? this.id,
    fileId: fileId ?? this.fileId,
    pageIndex: pageIndex ?? this.pageIndex,
    type: type ?? this.type,
    data: data ?? this.data,
    boundsLeft: boundsLeft ?? this.boundsLeft,
    boundsTop: boundsTop ?? this.boundsTop,
    boundsRight: boundsRight ?? this.boundsRight,
    boundsBottom: boundsBottom ?? this.boundsBottom,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Annotation copyWithCompanion(AnnotationsCompanion data) {
    return Annotation(
      id: data.id.present ? data.id.value : this.id,
      fileId: data.fileId.present ? data.fileId.value : this.fileId,
      pageIndex: data.pageIndex.present ? data.pageIndex.value : this.pageIndex,
      type: data.type.present ? data.type.value : this.type,
      data: data.data.present ? data.data.value : this.data,
      boundsLeft: data.boundsLeft.present
          ? data.boundsLeft.value
          : this.boundsLeft,
      boundsTop: data.boundsTop.present ? data.boundsTop.value : this.boundsTop,
      boundsRight: data.boundsRight.present
          ? data.boundsRight.value
          : this.boundsRight,
      boundsBottom: data.boundsBottom.present
          ? data.boundsBottom.value
          : this.boundsBottom,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Annotation(')
          ..write('id: $id, ')
          ..write('fileId: $fileId, ')
          ..write('pageIndex: $pageIndex, ')
          ..write('type: $type, ')
          ..write('data: $data, ')
          ..write('boundsLeft: $boundsLeft, ')
          ..write('boundsTop: $boundsTop, ')
          ..write('boundsRight: $boundsRight, ')
          ..write('boundsBottom: $boundsBottom, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    fileId,
    pageIndex,
    type,
    data,
    boundsLeft,
    boundsTop,
    boundsRight,
    boundsBottom,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Annotation &&
          other.id == this.id &&
          other.fileId == this.fileId &&
          other.pageIndex == this.pageIndex &&
          other.type == this.type &&
          other.data == this.data &&
          other.boundsLeft == this.boundsLeft &&
          other.boundsTop == this.boundsTop &&
          other.boundsRight == this.boundsRight &&
          other.boundsBottom == this.boundsBottom &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AnnotationsCompanion extends UpdateCompanion<Annotation> {
  final Value<String> id;
  final Value<String> fileId;
  final Value<int> pageIndex;
  final Value<int> type;
  final Value<String> data;
  final Value<double> boundsLeft;
  final Value<double> boundsTop;
  final Value<double> boundsRight;
  final Value<double> boundsBottom;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AnnotationsCompanion({
    this.id = const Value.absent(),
    this.fileId = const Value.absent(),
    this.pageIndex = const Value.absent(),
    this.type = const Value.absent(),
    this.data = const Value.absent(),
    this.boundsLeft = const Value.absent(),
    this.boundsTop = const Value.absent(),
    this.boundsRight = const Value.absent(),
    this.boundsBottom = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AnnotationsCompanion.insert({
    this.id = const Value.absent(),
    required String fileId,
    required int pageIndex,
    required int type,
    required String data,
    required double boundsLeft,
    required double boundsTop,
    required double boundsRight,
    required double boundsBottom,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : fileId = Value(fileId),
       pageIndex = Value(pageIndex),
       type = Value(type),
       data = Value(data),
       boundsLeft = Value(boundsLeft),
       boundsTop = Value(boundsTop),
       boundsRight = Value(boundsRight),
       boundsBottom = Value(boundsBottom);
  static Insertable<Annotation> custom({
    Expression<String>? id,
    Expression<String>? fileId,
    Expression<int>? pageIndex,
    Expression<int>? type,
    Expression<String>? data,
    Expression<double>? boundsLeft,
    Expression<double>? boundsTop,
    Expression<double>? boundsRight,
    Expression<double>? boundsBottom,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fileId != null) 'file_id': fileId,
      if (pageIndex != null) 'page_index': pageIndex,
      if (type != null) 'type': type,
      if (data != null) 'data': data,
      if (boundsLeft != null) 'bounds_left': boundsLeft,
      if (boundsTop != null) 'bounds_top': boundsTop,
      if (boundsRight != null) 'bounds_right': boundsRight,
      if (boundsBottom != null) 'bounds_bottom': boundsBottom,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AnnotationsCompanion copyWith({
    Value<String>? id,
    Value<String>? fileId,
    Value<int>? pageIndex,
    Value<int>? type,
    Value<String>? data,
    Value<double>? boundsLeft,
    Value<double>? boundsTop,
    Value<double>? boundsRight,
    Value<double>? boundsBottom,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return AnnotationsCompanion(
      id: id ?? this.id,
      fileId: fileId ?? this.fileId,
      pageIndex: pageIndex ?? this.pageIndex,
      type: type ?? this.type,
      data: data ?? this.data,
      boundsLeft: boundsLeft ?? this.boundsLeft,
      boundsTop: boundsTop ?? this.boundsTop,
      boundsRight: boundsRight ?? this.boundsRight,
      boundsBottom: boundsBottom ?? this.boundsBottom,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (fileId.present) {
      map['file_id'] = Variable<String>(fileId.value);
    }
    if (pageIndex.present) {
      map['page_index'] = Variable<int>(pageIndex.value);
    }
    if (type.present) {
      map['type'] = Variable<int>(type.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    if (boundsLeft.present) {
      map['bounds_left'] = Variable<double>(boundsLeft.value);
    }
    if (boundsTop.present) {
      map['bounds_top'] = Variable<double>(boundsTop.value);
    }
    if (boundsRight.present) {
      map['bounds_right'] = Variable<double>(boundsRight.value);
    }
    if (boundsBottom.present) {
      map['bounds_bottom'] = Variable<double>(boundsBottom.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AnnotationsCompanion(')
          ..write('id: $id, ')
          ..write('fileId: $fileId, ')
          ..write('pageIndex: $pageIndex, ')
          ..write('type: $type, ')
          ..write('data: $data, ')
          ..write('boundsLeft: $boundsLeft, ')
          ..write('boundsTop: $boundsTop, ')
          ..write('boundsRight: $boundsRight, ')
          ..write('boundsBottom: $boundsBottom, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AnnotationsTable annotations = $AnnotationsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [annotations];
}

typedef $$AnnotationsTableCreateCompanionBuilder =
    AnnotationsCompanion Function({
      Value<String> id,
      required String fileId,
      required int pageIndex,
      required int type,
      required String data,
      required double boundsLeft,
      required double boundsTop,
      required double boundsRight,
      required double boundsBottom,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$AnnotationsTableUpdateCompanionBuilder =
    AnnotationsCompanion Function({
      Value<String> id,
      Value<String> fileId,
      Value<int> pageIndex,
      Value<int> type,
      Value<String> data,
      Value<double> boundsLeft,
      Value<double> boundsTop,
      Value<double> boundsRight,
      Value<double> boundsBottom,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$AnnotationsTableFilterComposer
    extends Composer<_$AppDatabase, $AnnotationsTable> {
  $$AnnotationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileId => $composableBuilder(
    column: $table.fileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pageIndex => $composableBuilder(
    column: $table.pageIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get boundsLeft => $composableBuilder(
    column: $table.boundsLeft,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get boundsTop => $composableBuilder(
    column: $table.boundsTop,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get boundsRight => $composableBuilder(
    column: $table.boundsRight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get boundsBottom => $composableBuilder(
    column: $table.boundsBottom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AnnotationsTableOrderingComposer
    extends Composer<_$AppDatabase, $AnnotationsTable> {
  $$AnnotationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileId => $composableBuilder(
    column: $table.fileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pageIndex => $composableBuilder(
    column: $table.pageIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get boundsLeft => $composableBuilder(
    column: $table.boundsLeft,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get boundsTop => $composableBuilder(
    column: $table.boundsTop,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get boundsRight => $composableBuilder(
    column: $table.boundsRight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get boundsBottom => $composableBuilder(
    column: $table.boundsBottom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AnnotationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AnnotationsTable> {
  $$AnnotationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fileId =>
      $composableBuilder(column: $table.fileId, builder: (column) => column);

  GeneratedColumn<int> get pageIndex =>
      $composableBuilder(column: $table.pageIndex, builder: (column) => column);

  GeneratedColumn<int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<double> get boundsLeft => $composableBuilder(
    column: $table.boundsLeft,
    builder: (column) => column,
  );

  GeneratedColumn<double> get boundsTop =>
      $composableBuilder(column: $table.boundsTop, builder: (column) => column);

  GeneratedColumn<double> get boundsRight => $composableBuilder(
    column: $table.boundsRight,
    builder: (column) => column,
  );

  GeneratedColumn<double> get boundsBottom => $composableBuilder(
    column: $table.boundsBottom,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AnnotationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AnnotationsTable,
          Annotation,
          $$AnnotationsTableFilterComposer,
          $$AnnotationsTableOrderingComposer,
          $$AnnotationsTableAnnotationComposer,
          $$AnnotationsTableCreateCompanionBuilder,
          $$AnnotationsTableUpdateCompanionBuilder,
          (
            Annotation,
            BaseReferences<_$AppDatabase, $AnnotationsTable, Annotation>,
          ),
          Annotation,
          PrefetchHooks Function()
        > {
  $$AnnotationsTableTableManager(_$AppDatabase db, $AnnotationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AnnotationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AnnotationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AnnotationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> fileId = const Value.absent(),
                Value<int> pageIndex = const Value.absent(),
                Value<int> type = const Value.absent(),
                Value<String> data = const Value.absent(),
                Value<double> boundsLeft = const Value.absent(),
                Value<double> boundsTop = const Value.absent(),
                Value<double> boundsRight = const Value.absent(),
                Value<double> boundsBottom = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AnnotationsCompanion(
                id: id,
                fileId: fileId,
                pageIndex: pageIndex,
                type: type,
                data: data,
                boundsLeft: boundsLeft,
                boundsTop: boundsTop,
                boundsRight: boundsRight,
                boundsBottom: boundsBottom,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String fileId,
                required int pageIndex,
                required int type,
                required String data,
                required double boundsLeft,
                required double boundsTop,
                required double boundsRight,
                required double boundsBottom,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AnnotationsCompanion.insert(
                id: id,
                fileId: fileId,
                pageIndex: pageIndex,
                type: type,
                data: data,
                boundsLeft: boundsLeft,
                boundsTop: boundsTop,
                boundsRight: boundsRight,
                boundsBottom: boundsBottom,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AnnotationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AnnotationsTable,
      Annotation,
      $$AnnotationsTableFilterComposer,
      $$AnnotationsTableOrderingComposer,
      $$AnnotationsTableAnnotationComposer,
      $$AnnotationsTableCreateCompanionBuilder,
      $$AnnotationsTableUpdateCompanionBuilder,
      (
        Annotation,
        BaseReferences<_$AppDatabase, $AnnotationsTable, Annotation>,
      ),
      Annotation,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AnnotationsTableTableManager get annotations =>
      $$AnnotationsTableTableManager(_db, _db.annotations);
}
