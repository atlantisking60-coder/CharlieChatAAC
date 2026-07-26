# Room Database Schema

## Overview

This document provides a complete Room database schema for the Charlie Chat AAC communication app, including all entities, DAOs, relationships, indices, cascade deletes, and migration strategy.

---

## 1. Dependencies

```gradle
// build.gradle (app level)
dependencies {
    def room_version = "2.6.1"
    
    implementation "androidx.room:room-runtime:$room_version"
    implementation "androidx.room:room-ktx:$room_version"
    kapt "androidx.room:room-compiler:$room_version"
    
    // Optional: Coroutines support
    implementation "androidx.room:room-paging:$room_version"
}
```

---

## 2. Database Configuration

```kotlin
// com.charliechat.data.database.Charlie ChatDatabase
@Database(
    entities = [
        User::class,
        Profile::class,
        Board::class,
        Symbol::class,
        SymbolCategory::class,
        Sentence::class,
        Favorite::class,
        Setting::class,
        Language::class,
        AudioRecording::class,
        SharedBoard::class
    ],
    version = 1,
    exportSchema = true
)
@TypeConverters(Converters::class)
abstract class Charlie ChatDatabase : RoomDatabase() {
    
    abstract fun userDao(): UserDao
    abstract fun profileDao(): ProfileDao
    abstract fun boardDao(): BoardDao
    abstract fun symbolDao(): SymbolDao
    abstract fun symbolCategoryDao(): SymbolCategoryDao
    abstract fun sentenceDao(): SentenceDao
    abstract fun favoriteDao(): FavoriteDao
    abstract fun settingDao(): SettingDao
    abstract fun languageDao(): LanguageDao
    abstract fun audioRecordingDao(): AudioRecordingDao
    abstract fun sharedBoardDao(): SharedBoardDao
    
    companion object {
        @Volatile
        private var INSTANCE: Charlie ChatDatabase? = null
        
        fun getDatabase(context: Context): Charlie ChatDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    Charlie ChatDatabase::class.java,
                    "charliechat_database"
                )
                    .addCallback(DatabaseCallback())
                    .addMigrations(*ALL_MIGRATIONS)
                    .build()
                INSTANCE = instance
                instance
            }
        }
        
        val ALL_MIGRATIONS = arrayOf<Migration>(
            // Add migrations here when schema version changes
        )
    }
    
    private class DatabaseCallback : RoomDatabase.Callback() {
        override fun onCreate(db: SupportSQLiteDatabase) {
            super.onCreate(db)
            // Pre-populate database with initial data
        }
    }
}
```

---

## 3. Type Converters

```kotlin
// com.charliechat.data.database.Converters
class Converters {
    
    @TypeConverter
    fun fromTimestamp(value: Long?): Date? {
        return value?.let { Date(it) }
    }
    
    @TypeConverter
    fun dateToTimestamp(date: Date?): Long? {
        return date?.time
    }
    
    @TypeConverter
    fun fromStringList(value: List<String>?): String? {
        return value?.joinToString(",")
    }
    
    @TypeConverter
    fun toStringList(data: String?): List<String>? {
        return data?.split(",")
    }
    
    @TypeConverter
    fun fromJsonObject(value: Map<String, Any>?): String? {
        return value?.let { Gson().toJson(it) }
    }
    
    @TypeConverter
    fun toJsonObject(data: String?): Map<String, Any>? {
        return data?.let { 
            val type = object : TypeToken<Map<String, Any>>() {}.type
            Gson().fromJson(it, type)
        }
    }
    
    @TypeConverter
    fun fromBoolean(value: Boolean?): Int? {
        return value?.let { if (it) 1 else 0 }
    }
    
    @TypeConverter
    fun toBoolean(value: Int?): Boolean? {
        return value?.let { it == 1 }
    }
}
```

---

## 4. Entities

### User Entity

```kotlin
// com.charliechat.data.database.entity.User
@Entity(
    tableName = "users",
    indices = [
        Index(value = ["email"], unique = true),
        Index(value = ["username"], unique = true),
        Index(value = ["created_at"])
    ]
)
data class User(
    @PrimaryKey(autoGenerate = true)
    @ColumnInfo(name = "user_id")
    val userId: Long = 0,
    
    @ColumnInfo(name = "email")
    val email: String,
    
    @ColumnInfo(name = "username")
    val username: String,
    
    @ColumnInfo(name = "display_name")
    val displayName: String?,
    
    @ColumnInfo(name = "password_hash")
    val passwordHash: String,
    
    @ColumnInfo(name = "avatar_url")
    val avatarUrl: String?,
    
    @ColumnInfo(name = "is_active")
    val isActive: Boolean = true,
    
    @ColumnInfo(name = "is_admin")
    val isAdmin: Boolean = false,
    
    @ColumnInfo(name = "email_verified")
    val emailVerified: Boolean = false,
    
    @ColumnInfo(name = "created_at")
    val createdAt: Date = Date(),
    
    @ColumnInfo(name = "updated_at")
    val updatedAt: Date = Date(),
    
    @ColumnInfo(name = "last_login_at")
    val lastLoginAt: Date?
)
```

### Profile Entity

```kotlin
// com.charliechat.data.database.entity.Profile
@Entity(
    tableName = "profiles",
    indices = [
        Index(value = ["user_id"]),
        Index(value = ["name"]),
        Index(value = ["is_active"])
    ],
    foreignKeys = [
        ForeignKey(
            entity = User::class,
            parentColumns = ["user_id"],
            childColumns = ["user_id"],
            onDelete = ForeignKey.CASCADE,
            onUpdate = ForeignKey.CASCADE
        )
    ]
)
data class Profile(
    @PrimaryKey(autoGenerate = true)
    @ColumnInfo(name = "profile_id")
    val profileId: Long = 0,
    
    @ColumnInfo(name = "user_id")
    val userId: Long,
    
    @ColumnInfo(name = "name")
    val name: String,
    
    @ColumnInfo(name = "avatar_url")
    val avatarUrl: String?,
    
    @ColumnInfo(name = "settings_json")
    val settingsJson: String,
    
    @ColumnInfo(name = "tab_order_json")
    val tabOrderJson: String = "[]",
    
    @ColumnInfo(name = "preferred_symbol_sets_json")
    val preferredSymbolSetsJson: String = "[]",
    
    @ColumnInfo(name = "starting_board_id")
    val startingBoardId: Long?,
    
    @ColumnInfo(name = "is_active")
    val isActive: Boolean = true,
    
    @ColumnInfo(name = "created_at")
    val createdAt: Date = Date(),
    
    @ColumnInfo(name = "updated_at")
    val updatedAt: Date = Date(),
    
    @ColumnInfo(name = "last_used_at")
    val lastUsedAt: Date?
)
```

### Board Entity

```kotlin
// com.charliechat.data.database.entity.Board
@Entity(
    tableName = "boards",
    indices = [
        Index(value = ["profile_id"]),
        Index(value = ["name"]),
        Index(value = ["parent_board_id"]),
        Index(value = ["is_public"]),
        Index(value = ["is_deleted"]),
        Index(value = ["updated_at"])
    ],
    foreignKeys = [
        ForeignKey(
            entity = Profile::class,
            parentColumns = ["profile_id"],
            childColumns = ["profile_id"],
            onDelete = ForeignKey.CASCADE,
            onUpdate = ForeignKey.CASCADE
        ),
        ForeignKey(
            entity = Board::class,
            parentColumns = ["board_id"],
            childColumns = ["parent_board_id"],
            onDelete = ForeignKey.CASCADE,
            onUpdate = ForeignKey.CASCADE
        )
    ]
)
data class Board(
    @PrimaryKey(autoGenerate = true)
    @ColumnInfo(name = "board_id")
    val boardId: Long = 0,
    
    @ColumnInfo(name = "profile_id")
    val profileId: Long,
    
    @ColumnInfo(name = "name")
    val name: String,
    
    @ColumnInfo(name = "description")
    val description: String?,
    
    @ColumnInfo(name = "rows")
    val rows: Int = 6,
    
    @ColumnInfo(name = "columns")
    val columns: Int = 5,
    
    @ColumnInfo(name = "adjustable_layout")
    val adjustableLayout: Boolean = false,
    
    @ColumnInfo(name = "box_scale")
    val boxScale: Float = 1.0f,
    
    @ColumnInfo(name = "tile_height")
    val tileHeight: Float = 100.0f,
    
    @ColumnInfo(name = "tile_width")
    val tileWidth: Float = 100.0f,
    
    @ColumnInfo(name = "background_color")
    val backgroundColor: String = "#FFFFFF",
    
    @ColumnInfo(name = "is_sub_board")
    val isSubBoard: Boolean = false,
    
    @ColumnInfo(name = "parent_board_id")
    val parentBoardId: Long?,
    
    @ColumnInfo(name = "is_public")
    val isPublic: Boolean = false,
    
    @ColumnInfo(name = "is_deleted")
    val isDeleted: Boolean = false,
    
    @ColumnInfo(name = "version")
    val version: Int = 1,
    
    @ColumnInfo(name = "cloud_id")
    val cloudId: String?,
    
    @ColumnInfo(name = "synced_at")
    val syncedAt: Date?,
    
    @ColumnInfo(name = "created_at")
    val createdAt: Date = Date(),
    
    @ColumnInfo(name = "updated_at")
    val updatedAt: Date = Date()
)
```

### Symbol Entity

```kotlin
// com.charliechat.data.database.entity.Symbol
@Entity(
    tableName = "symbols",
    indices = [
        Index(value = ["board_id"]),
        Index(value = ["category_id"]),
        Index(value = ["label"]),
        Index(value = ["position"]),
        Index(value = ["is_board_link"])
    ],
    foreignKeys = [
        ForeignKey(
            entity = Board::class,
            parentColumns = ["board_id"],
            childColumns = ["board_id"],
            onDelete = ForeignKey.CASCADE,
            onUpdate = ForeignKey.CASCADE
        ),
        ForeignKey(
            entity = SymbolCategory::class,
            parentColumns = ["category_id"],
            childColumns = ["category_id"],
            onDelete = ForeignKey.SET_NULL,
            onUpdate = ForeignKey.CASCADE
        )
    ]
)
data class Symbol(
    @PrimaryKey(autoGenerate = true)
    @ColumnInfo(name = "symbol_id")
    val symbolId: Long = 0,
    
    @ColumnInfo(name = "board_id")
    val boardId: Long,
    
    @ColumnInfo(name = "category_id")
    val categoryId: Long?,
    
    @ColumnInfo(name = "label")
    val label: String,
    
    @ColumnInfo(name = "description")
    val description: String?,
    
    @ColumnInfo(name = "image_path")
    val imagePath: String?,
    
    @ColumnInfo(name = "emoji")
    val emoji: String?,
    
    @ColumnInfo(name = "linked_board_id")
    val linkedBoardId: Long?,
    
    @ColumnInfo(name = "is_board_link")
    val isBoardLink: Boolean = false,
    
    @ColumnInfo(name = "tile_size")
    val tileSize: Float = 1.0f,
    
    @ColumnInfo(name = "background_color")
    val backgroundColor: String = "#FFFFFF",
    
    @ColumnInfo(name = "text_color")
    val textColor: String = "#000000",
    
    @ColumnInfo(name = "custom_voice")
    val customVoice: String?,
    
    @ColumnInfo(name = "position")
    val position: Int = 0,
    
    @ColumnInfo(name = "row")
    val row: Int?,
    
    @ColumnInfo(name = "column")
    val column: Int?,
    
    @ColumnInfo(name = "is_favorite")
    val isFavorite: Boolean = false,
    
    @ColumnInfo(name = "usage_count")
    val usageCount: Int = 0,
    
    @ColumnInfo(name = "last_used_at")
    val lastUsedAt: Date?,
    
    @ColumnInfo(name = "cloud_id")
    val cloudId: String?,
    
    @ColumnInfo(name = "synced_at")
    val syncedAt: Date?,
    
    @ColumnInfo(name = "created_at")
    val createdAt: Date = Date(),
    
    @ColumnInfo(name = "updated_at")
    val updatedAt: Date = Date()
)
```

### SymbolCategory Entity

```kotlin
// com.charliechat.data.database.entity.SymbolCategory
@Entity(
    tableName = "symbol_categories",
    indices = [
        Index(value = ["profile_id"]),
        Index(value = ["name"]),
        Index(value = ["parent_category_id"])
    ],
    foreignKeys = [
        ForeignKey(
            entity = Profile::class,
            parentColumns = ["profile_id"],
            childColumns = ["profile_id"],
            onDelete = ForeignKey.CASCADE,
            onUpdate = ForeignKey.CASCADE
        ),
        ForeignKey(
            entity = SymbolCategory::class,
            parentColumns = ["category_id"],
            childColumns = ["parent_category_id"],
            onDelete = ForeignKey.CASCADE,
            onUpdate = ForeignKey.CASCADE
        )
    ]
)
data class SymbolCategory(
    @PrimaryKey(autoGenerate = true)
    @ColumnInfo(name = "category_id")
    val categoryId: Long = 0,
    
    @ColumnInfo(name = "profile_id")
    val profileId: Long,
    
    @ColumnInfo(name = "name")
    val name: String,
    
    @ColumnInfo(name = "description")
    val description: String?,
    
    @ColumnInfo(name = "icon")
    val icon: String?,
    
    @ColumnInfo(name = "color")
    val color: String = "#FF0000",
    
    @ColumnInfo(name = "parent_category_id")
    val parentCategoryId: Long?,
    
    @ColumnInfo(name = "sort_order")
    val sortOrder: Int = 0,
    
    @ColumnInfo(name = "is_system")
    val isSystem: Boolean = false,
    
    @ColumnInfo(name = "cloud_id")
    val cloudId: String?,
    
    @ColumnInfo(name = "created_at")
    val createdAt: Date = Date(),
    
    @ColumnInfo(name = "updated_at")
    val updatedAt: Date = Date()
)
```

### Sentence Entity

```kotlin
// com.charliechat.data.database.entity.Sentence
@Entity(
    tableName = "sentences",
    indices = [
        Index(value = ["profile_id"]),
        Index(value = ["created_at"]),
        Index(value = ["is_favorite"])
    ],
    foreignKeys = [
        ForeignKey(
            entity = Profile::class,
            parentColumns = ["profile_id"],
            childColumns = ["profile_id"],
            onDelete = ForeignKey.CASCADE,
            onUpdate = ForeignKey.CASCADE
        )
    ]
)
data class Sentence(
    @PrimaryKey(autoGenerate = true)
    @ColumnInfo(name = "sentence_id")
    val sentenceId: Long = 0,
    
    @ColumnInfo(name = "profile_id")
    val profileId: Long,
    
    @ColumnInfo(name = "text")
    val text: String,
    
    @ColumnInfo(name = "symbol_ids_json")
    val symbolIdsJson: String,
    
    @ColumnInfo(name = "is_favorite")
    val isFavorite: Boolean = false,
    
    @ColumnInfo(name = "usage_count")
    val usageCount: Int = 0,
    
    @ColumnInfo(name = "cloud_id")
    val cloudId: String?,
    
    @ColumnInfo(name = "synced_at")
    val syncedAt: Date?,
    
    @ColumnInfo(name = "created_at")
    val createdAt: Date = Date()
)
```

### Favorite Entity

```kotlin
// com.charliechat.data.database.entity.Favorite
@Entity(
    tableName = "favorites",
    indices = [
        Index(value = ["profile_id"]),
        Index(value = ["symbol_id"], unique = true),
        Index(value = ["added_at"])
    ],
    foreignKeys = [
        ForeignKey(
            entity = Profile::class,
            parentColumns = ["profile_id"],
            childColumns = ["profile_id"],
            onDelete = ForeignKey.CASCADE,
            onUpdate = ForeignKey.CASCADE
        ),
        ForeignKey(
            entity = Symbol::class,
            parentColumns = ["symbol_id"],
            childColumns = ["symbol_id"],
            onDelete = ForeignKey.CASCADE,
            onUpdate = ForeignKey.CASCADE
        )
    ]
)
data class Favorite(
    @PrimaryKey(autoGenerate = true)
    @ColumnInfo(name = "favorite_id")
    val favoriteId: Long = 0,
    
    @ColumnInfo(name = "profile_id")
    val profileId: Long,
    
    @ColumnInfo(name = "symbol_id")
    val symbolId: Long,
    
    @ColumnInfo(name = "added_at")
    val addedAt: Date = Date()
)
```

### Setting Entity

```kotlin
// com.charliechat.data.database.entity.Setting
@Entity(
    tableName = "settings",
    indices = [
        Index(value = ["profile_id"], unique = true),
        Index(value = ["key"])
    ],
    foreignKeys = [
        ForeignKey(
            entity = Profile::class,
            parentColumns = ["profile_id"],
            childColumns = ["profile_id"],
            onDelete = ForeignKey.CASCADE,
            onUpdate = ForeignKey.CASCADE
        )
    ]
)
data class Setting(
    @PrimaryKey(autoGenerate = true)
    @ColumnInfo(name = "setting_id")
    val settingId: Long = 0,
    
    @ColumnInfo(name = "profile_id")
    val profileId: Long,
    
    @ColumnInfo(name = "key")
    val key: String,
    
    @ColumnInfo(name = "value")
    val value: String,
    
    @ColumnInfo(name = "value_type")
    val valueType: String = "string", // string, int, bool, float
    
    @ColumnInfo(name = "updated_at")
    val updatedAt: Date = Date()
)
```

### Language Entity

```kotlin
// com.charliechat.data.database.entity.Language
@Entity(
    tableName = "languages",
    indices = [
        Index(value = ["code"], unique = true),
        Index(value = ["name"]),
        Index(value = ["is_active"])
    ]
)
data class Language(
    @PrimaryKey(autoGenerate = true)
    @ColumnInfo(name = "language_id")
    val languageId: Long = 0,
    
    @ColumnInfo(name = "code")
    val code: String,
    
    @ColumnInfo(name = "name")
    val name: String,
    
    @ColumnInfo(name = "native_name")
    val nativeName: String,
    
    @ColumnInfo(name = "flag_emoji")
    val flagEmoji: String?,
    
    @ColumnInfo(name = "is_active")
    val isActive: Boolean = true,
    
    @ColumnInfo(name = "is_system")
    val isSystem: Boolean = true,
    
    @ColumnInfo(name = "created_at")
    val createdAt: Date = Date()
)
```

### AudioRecording Entity

```kotlin
// com.charliechat.data.database.entity.AudioRecording
@Entity(
    tableName = "audio_recordings",
    indices = [
        Index(value = ["profile_id"]),
        Index(value = ["symbol_id"]),
        Index(value = ["language_code"]),
        Index(value = ["created_at"])
    ],
    foreignKeys = [
        ForeignKey(
            entity = Profile::class,
            parentColumns = ["profile_id"],
            childColumns = ["profile_id"],
            onDelete = ForeignKey.CASCADE,
            onUpdate = ForeignKey.CASCADE
        ),
        ForeignKey(
            entity = Symbol::class,
            parentColumns = ["symbol_id"],
            childColumns = ["symbol_id"],
            onDelete = ForeignKey.CASCADE,
            onUpdate = ForeignKey.CASCADE
        )
    ]
)
data class AudioRecording(
    @PrimaryKey(autoGenerate = true)
    @ColumnInfo(name = "recording_id")
    val recordingId: Long = 0,
    
    @ColumnInfo(name = "profile_id")
    val profileId: Long,
    
    @ColumnInfo(name = "symbol_id")
    val symbolId: Long?,
    
    @ColumnInfo(name = "language_code")
    val languageCode: String,
    
    @ColumnInfo(name = "file_path")
    val filePath: String,
    
    @ColumnInfo(name = "duration_ms")
    val durationMs: Int,
    
    @ColumnInfo(name = "file_size_bytes")
    val fileSizeBytes: Long,
    
    @ColumnInfo(name = "is_custom")
    val isCustom: Boolean = false,
    
    @ColumnInfo(name = "cloud_id")
    val cloudId: String?,
    
    @ColumnInfo(name = "synced_at")
    val syncedAt: Date?,
    
    @ColumnInfo(name = "created_at")
    val createdAt: Date = Date()
)
```

### SharedBoard Entity

```kotlin
// com.charliechat.data.database.entity.SharedBoard
@Entity(
    tableName = "shared_boards",
    indices = [
        Index(value = ["board_id"]),
        Index(value = ["shared_with_user_id"]),
        Index(value = ["shared_by_user_id"]),
        Index(value = ["permission"]),
        Index(value = ["status"]),
        Index(value = ["created_at"])
    ],
    foreignKeys = [
        ForeignKey(
            entity = Board::class,
            parentColumns = ["board_id"],
            childColumns = ["board_id"],
            onDelete = ForeignKey.CASCADE,
            onUpdate = ForeignKey.CASCADE
        ),
        ForeignKey(
            entity = User::class,
            parentColumns = ["user_id"],
            childColumns = ["shared_with_user_id"],
            onDelete = ForeignKey.CASCADE,
            onUpdate = ForeignKey.CASCADE
        ),
        ForeignKey(
            entity = User::class,
            parentColumns = ["user_id"],
            childColumns = ["shared_by_user_id"],
            onDelete = ForeignKey.CASCADE,
            onUpdate = ForeignKey.CASCADE
        )
    ]
)
data class SharedBoard(
    @PrimaryKey(autoGenerate = true)
    @ColumnInfo(name = "share_id")
    val shareId: Long = 0,
    
    @ColumnInfo(name = "board_id")
    val boardId: Long,
    
    @ColumnInfo(name = "shared_with_user_id")
    val sharedWithUserId: Long,
    
    @ColumnInfo(name = "shared_by_user_id")
    val sharedByUserId: Long,
    
    @ColumnInfo(name = "permission")
    val permission: String = "view", // view, edit
    
    @ColumnInfo(name = "status")
    val status: String = "pending", // pending, accepted, declined
    
    @ColumnInfo(name = "expires_at")
    val expiresAt: Date?,
    
    @ColumnInfo(name = "message")
    val message: String?,
    
    @ColumnInfo(name = "cloud_id")
    val cloudId: String?,
    
    @ColumnInfo(name = "synced_at")
    val syncedAt: Date?,
    
    @ColumnInfo(name = "created_at")
    val createdAt: Date = Date()
)
```

---

## 5. DAO Interfaces

### UserDao

```kotlin
// com.charliechat.data.database.dao.UserDao
@Dao
interface UserDao {
    
    @Query("SELECT * FROM users WHERE user_id = :userId")
    suspend fun getUserById(userId: Long): User?
    
    @Query("SELECT * FROM users WHERE email = :email")
    suspend fun getUserByEmail(email: String): User?
    
    @Query("SELECT * FROM users WHERE username = :username")
    suspend fun getUserByUsername(username: String): User?
    
    @Query("SELECT * FROM users WHERE is_active = 1")
    suspend fun getAllActiveUsers(): List<User>
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertUser(user: User): Long
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertUsers(users: List<User>): List<Long>
    
    @Update
    suspend fun updateUser(user: User)
    
    @Delete
    suspend fun deleteUser(user: User)
    
    @Query("DELETE FROM users WHERE user_id = :userId")
    suspend fun deleteUserById(userId: Long)
    
    @Query("UPDATE users SET last_login_at = :timestamp WHERE user_id = :userId")
    suspend fun updateLastLogin(userId: Long, timestamp: Date = Date())
    
    @Query("UPDATE users SET email_verified = 1 WHERE user_id = :userId")
    suspend fun verifyEmail(userId: Long)
}
```

### ProfileDao

```kotlin
// com.charliechat.data.database.dao.ProfileDao
@Dao
interface ProfileDao {
    
    @Query("SELECT * FROM profiles WHERE profile_id = :profileId")
    suspend fun getProfileById(profileId: Long): Profile?
    
    @Query("SELECT * FROM profiles WHERE user_id = :userId")
    suspend fun getProfilesByUserId(userId: Long): List<Profile>
    
    @Query("SELECT * FROM profiles WHERE user_id = :userId AND is_active = 1")
    suspend fun getActiveProfilesByUserId(userId: Long): List<Profile>
    
    @Query("SELECT * FROM profiles WHERE is_active = 1 ORDER BY last_used_at DESC LIMIT 1")
    suspend fun getLastUsedProfile(): Profile?
    
    @Query("SELECT * FROM profiles WHERE name = :name")
    suspend fun getProfileByName(name: String): Profile?
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertProfile(profile: Profile): Long
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertProfiles(profiles: List<Profile>): List<Long>
    
    @Update
    suspend fun updateProfile(profile: Profile)
    
    @Delete
    suspend fun deleteProfile(profile: Profile)
    
    @Query("DELETE FROM profiles WHERE profile_id = :profileId")
    suspend fun deleteProfileById(profileId: Long)
    
    @Query("UPDATE profiles SET is_active = 0 WHERE user_id = :userId")
    suspend fun deactivateAllProfiles(userId: Long)
    
    @Query("UPDATE profiles SET is_active = 1, last_used_at = :timestamp WHERE profile_id = :profileId")
    suspend fun activateProfile(profileId: Long, timestamp: Date = Date())
    
    @Transaction
    @Query("SELECT * FROM profiles WHERE profile_id = :profileId")
    suspend fun getProfileWithBoards(profileId: Long): ProfileWithBoards?
}
```

### BoardDao

```kotlin
// com.charliechat.data.database.dao.BoardDao
@Dao
interface BoardDao {
    
    @Query("SELECT * FROM boards WHERE board_id = :boardId")
    suspend fun getBoardById(boardId: Long): Board?
    
    @Query("SELECT * FROM boards WHERE profile_id = :profileId AND is_deleted = 0")
    suspend fun getBoardsByProfileId(profileId: Long): List<Board>
    
    @Query("SELECT * FROM boards WHERE profile_id = :profileId AND is_deleted = 0 AND is_sub_board = 0")
    suspend fun getMainBoardsByProfileId(profileId: Long): List<Board>
    
    @Query("SELECT * FROM boards WHERE parent_board_id = :parentBoardId AND is_deleted = 0")
    suspend fun getSubBoards(parentBoardId: Long): List<Board>
    
    @Query("SELECT * FROM boards WHERE cloud_id = :cloudId")
    suspend fun getBoardByCloudId(cloudId: String): Board?
    
    @Query("SELECT * FROM boards WHERE is_public = 1 AND is_deleted = 0")
    suspend fun getPublicBoards(): List<Board>
    
    @Query("SELECT * FROM boards WHERE name LIKE :query AND is_deleted = 0")
    suspend fun searchBoards(query: String): List<Board>
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertBoard(board: Board): Long
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertBoards(boards: List<Board>): List<Long>
    
    @Update
    suspend fun updateBoard(board: Board)
    
    @Delete
    suspend fun deleteBoard(board: Board)
    
    @Query("UPDATE boards SET is_deleted = 1, updated_at = :timestamp WHERE board_id = :boardId")
    suspend fun softDeleteBoard(boardId: Long, timestamp: Date = Date())
    
    @Query("DELETE FROM boards WHERE board_id = :boardId")
    suspend fun hardDeleteBoard(boardId: Long)
    
    @Query("UPDATE boards SET synced_at = :timestamp WHERE board_id = :boardId")
    suspend fun updateSyncTimestamp(boardId: Long, timestamp: Date = Date())
    
    @Transaction
    @Query("SELECT * FROM boards WHERE board_id = :boardId")
    suspend fun getBoardWithSymbols(boardId: Long): BoardWithSymbols?
    
    @Transaction
    @Query("SELECT * FROM boards WHERE board_id = :boardId")
    suspend fun getBoardWithSubBoards(boardId: Long): BoardWithSubBoards?
}
```

### SymbolDao

```kotlin
// com.charliechat.data.database.dao.SymbolDao
@Dao
interface SymbolDao {
    
    @Query("SELECT * FROM symbols WHERE symbol_id = :symbolId")
    suspend fun getSymbolById(symbolId: Long): Symbol?
    
    @Query("SELECT * FROM symbols WHERE board_id = :boardId ORDER BY position ASC")
    suspend fun getSymbolsByBoardId(boardId: Long): List<Symbol>
    
    @Query("SELECT * FROM symbols WHERE board_id = :boardId AND row = :row AND column = :column")
    suspend fun getSymbolAtPosition(boardId: Long, row: Int, column: Int): Symbol?
    
    @Query("SELECT * FROM symbols WHERE category_id = :categoryId")
    suspend fun getSymbolsByCategoryId(categoryId: Long): List<Symbol>
    
    @Query("SELECT * FROM symbols WHERE label LIKE :query")
    suspend fun searchSymbols(query: String): List<Symbol>
    
    @Query("SELECT * FROM symbols WHERE is_favorite = 1 ORDER BY last_used_at DESC")
    suspend fun getFavoriteSymbols(): List<Symbol>
    
    @Query("SELECT * FROM symbols ORDER BY usage_count DESC LIMIT :limit")
    suspend fun getMostUsedSymbols(limit: Int = 20): List<Symbol>
    
    @Query("SELECT * FROM symbols WHERE cloud_id = :cloudId")
    suspend fun getSymbolByCloudId(cloudId: String): Symbol?
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertSymbol(symbol: Symbol): Long
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertSymbols(symbols: List<Symbol>): List<Long>
    
    @Update
    suspend fun updateSymbol(symbol: Symbol)
    
    @Delete
    suspend fun deleteSymbol(symbol: Symbol)
    
    @Query("DELETE FROM symbols WHERE board_id = :boardId")
    suspend fun deleteSymbolsByBoardId(boardId: Long)
    
    @Query("UPDATE symbols SET usage_count = usage_count + 1, last_used_at = :timestamp WHERE symbol_id = :symbolId")
    suspend fun incrementUsageCount(symbolId: Long, timestamp: Date = Date())
    
    @Query("UPDATE symbols SET is_favorite = :isFavorite WHERE symbol_id = :symbolId")
    suspend fun updateFavoriteStatus(symbolId: Long, isFavorite: Boolean)
    
    @Query("UPDATE symbols SET synced_at = :timestamp WHERE symbol_id = :symbolId")
    suspend fun updateSyncTimestamp(symbolId: Long, timestamp: Date = Date())
}
```

### SymbolCategoryDao

```kotlin
// com.charliechat.data.database.dao.SymbolCategoryDao
@Dao
interface SymbolCategoryDao {
    
    @Query("SELECT * FROM symbol_categories WHERE category_id = :categoryId")
    suspend fun getCategoryById(categoryId: Long): SymbolCategory?
    
    @Query("SELECT * FROM symbol_categories WHERE profile_id = :profileId ORDER BY sort_order ASC")
    suspend fun getCategoriesByProfileId(profileId: Long): List<SymbolCategory>
    
    @Query("SELECT * FROM symbol_categories WHERE parent_category_id = :parentCategoryId")
    suspend fun getSubCategories(parentCategoryId: Long): List<SymbolCategory>
    
    @Query("SELECT * FROM symbol_categories WHERE is_system = 1")
    suspend fun getSystemCategories(): List<SymbolCategory>
    
    @Query("SELECT * FROM symbol_categories WHERE name LIKE :query")
    suspend fun searchCategories(query: String): List<SymbolCategory>
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertCategory(category: SymbolCategory): Long
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertCategories(categories: List<SymbolCategory>): List<Long>
    
    @Update
    suspend fun updateCategory(category: SymbolCategory)
    
    @Delete
    suspend fun deleteCategory(category: SymbolCategory)
    
    @Query("DELETE FROM symbol_categories WHERE profile_id = :profileId")
    suspend fun deleteCategoriesByProfileId(profileId: Long)
}
```

### SentenceDao

```kotlin
// com.charliechat.data.database.dao.SentenceDao
@Dao
interface SentenceDao {
    
    @Query("SELECT * FROM sentences WHERE sentence_id = :sentenceId")
    suspend fun getSentenceById(sentenceId: Long): Sentence?
    
    @Query("SELECT * FROM sentences WHERE profile_id = :profileId ORDER BY created_at DESC LIMIT :limit")
    suspend fun getSentencesByProfileId(profileId: Long, limit: Int = 50): List<Sentence>
    
    @Query("SELECT * FROM sentences WHERE profile_id = :profileId AND is_favorite = 1 ORDER BY created_at DESC")
    suspend fun getFavoriteSentences(profileId: Long): List<Sentence>
    
    @Query("SELECT * FROM sentences WHERE text LIKE :query")
    suspend fun searchSentences(query: String): List<Sentence>
    
    @Query("SELECT * FROM sentences ORDER BY usage_count DESC LIMIT :limit")
    suspend fun getMostUsedSentences(limit: Int = 20): List<Sentence>
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertSentence(sentence: Sentence): Long
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertSentences(sentences: List<Sentence>): List<Long>
    
    @Update
    suspend fun updateSentence(sentence: Sentence)
    
    @Delete
    suspend fun deleteSentence(sentence: Sentence)
    
    @Query("DELETE FROM sentences WHERE profile_id = :profileId")
    suspend fun deleteSentencesByProfileId(profileId: Long)
    
    @Query("UPDATE sentences SET usage_count = usage_count + 1 WHERE sentence_id = :sentenceId")
    suspend fun incrementUsageCount(sentenceId: Long)
    
    @Query("UPDATE sentences SET is_favorite = :isFavorite WHERE sentence_id = :sentenceId")
    suspend fun updateFavoriteStatus(sentenceId: Long, isFavorite: Boolean)
}
```

### FavoriteDao

```kotlin
// com.charliechat.data.database.dao.FavoriteDao
@Dao
interface FavoriteDao {
    
    @Query("SELECT * FROM favorites WHERE favorite_id = :favoriteId")
    suspend fun getFavoriteById(favoriteId: Long): Favorite?
    
    @Query("SELECT * FROM favorites WHERE profile_id = :profileId")
    suspend fun getFavoritesByProfileId(profileId: Long): List<Favorite>
    
    @Query("SELECT * FROM favorites WHERE profile_id = :profileId AND symbol_id = :symbolId")
    suspend fun getFavorite(profileId: Long, symbolId: Long): Favorite?
    
    @Query("SELECT s.* FROM symbols s INNER JOIN favorites f ON s.symbol_id = f.symbol_id WHERE f.profile_id = :profileId ORDER BY f.added_at DESC")
    suspend fun getFavoriteSymbolsWithProfileId(profileId: Long): List<Symbol>
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertFavorite(favorite: Favorite): Long
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertFavorites(favorites: List<Favorite>): List<Long>
    
    @Delete
    suspend fun deleteFavorite(favorite: Favorite)
    
    @Query("DELETE FROM favorites WHERE profile_id = :profileId AND symbol_id = :symbolId")
    suspend fun deleteFavorite(profileId: Long, symbolId: Long)
    
    @Query("DELETE FROM favorites WHERE profile_id = :profileId")
    suspend fun deleteFavoritesByProfileId(profileId: Long)
    
    @Query("DELETE FROM favorites WHERE symbol_id = :symbolId")
    suspend fun deleteFavoritesBySymbolId(symbolId: Long)
}
```

### SettingDao

```kotlin
// com.charliechat.data.database.dao.SettingDao
@Dao
interface SettingDao {
    
    @Query("SELECT * FROM settings WHERE setting_id = :settingId")
    suspend fun getSettingById(settingId: Long): Setting?
    
    @Query("SELECT * FROM settings WHERE profile_id = :profileId")
    suspend fun getSettingsByProfileId(profileId: Long): List<Setting>
    
    @Query("SELECT * FROM settings WHERE profile_id = :profileId AND `key` = :key")
    suspend fun getSetting(profileId: Long, key: String): Setting?
    
    @Query("SELECT value FROM settings WHERE profile_id = :profileId AND `key` = :key")
    suspend fun getSettingValue(profileId: Long, key: String): String?
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertSetting(setting: Setting): Long
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertSettings(settings: List<Setting>): List<Long>
    
    @Update
    suspend fun updateSetting(setting: Setting)
    
    @Delete
    suspend fun deleteSetting(setting: Setting)
    
    @Query("DELETE FROM settings WHERE profile_id = :profileId")
    suspend fun deleteSettingsByProfileId(profileId: Long)
    
    @Query("UPDATE settings SET value = :value, updated_at = :timestamp WHERE profile_id = :profileId AND `key` = :key")
    suspend fun updateSettingValue(profileId: Long, key: String, value: String, timestamp: Date = Date())
}
```

### LanguageDao

```kotlin
// com.charliechat.data.database.dao.LanguageDao
@Dao
interface LanguageDao {
    
    @Query("SELECT * FROM languages WHERE language_id = :languageId")
    suspend fun getLanguageById(languageId: Long): Language?
    
    @Query("SELECT * FROM languages WHERE code = :code")
    suspend fun getLanguageByCode(code: String): Language?
    
    @Query("SELECT * FROM languages WHERE is_active = 1 ORDER BY name ASC")
    suspend fun getActiveLanguages(): List<Language>
    
    @Query("SELECT * FROM languages WHERE is_system = 1")
    suspend fun getSystemLanguages(): List<Language>
    
    @Query("SELECT * FROM languages WHERE name LIKE :query")
    suspend fun searchLanguages(query: String): List<Language>
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertLanguage(language: Language): Long
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertLanguages(languages: List<Language>): List<Long>
    
    @Update
    suspend fun updateLanguage(language: Language)
    
    @Delete
    suspend fun deleteLanguage(language: Language)
}
```

### AudioRecordingDao

```kotlin
// com.charliechat.data.database.dao.AudioRecordingDao
@Dao
interface AudioRecordingDao {
    
    @Query("SELECT * FROM audio_recordings WHERE recording_id = :recordingId")
    suspend fun getRecordingById(recordingId: Long): AudioRecording?
    
    @Query("SELECT * FROM audio_recordings WHERE profile_id = :profileId")
    suspend fun getRecordingsByProfileId(profileId: Long): List<AudioRecording>
    
    @Query("SELECT * FROM audio_recordings WHERE symbol_id = :symbolId")
    suspend fun getRecordingsBySymbolId(symbolId: Long): List<AudioRecording>
    
    @Query("SELECT * FROM audio_recordings WHERE symbol_id = :symbolId AND language_code = :languageCode")
    suspend fun getRecordingForSymbol(symbolId: Long, languageCode: String): AudioRecording?
    
    @Query("SELECT * FROM audio_recordings WHERE language_code = :languageCode AND is_custom = 0")
    suspend fun getSystemRecordingsByLanguage(languageCode: String): List<AudioRecording>
    
    @Query("SELECT * FROM audio_recordings WHERE is_custom = 1")
    suspend fun getCustomRecordings(): List<AudioRecording>
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertRecording(recording: AudioRecording): Long
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertRecordings(recordings: List<AudioRecording>): List<Long>
    
    @Update
    suspend fun updateRecording(recording: AudioRecording)
    
    @Delete
    suspend fun deleteRecording(recording: AudioRecording)
    
    @Query("DELETE FROM audio_recordings WHERE profile_id = :profileId")
    suspend fun deleteRecordingsByProfileId(profileId: Long)
    
    @Query("DELETE FROM audio_recordings WHERE symbol_id = :symbolId")
    suspend fun deleteRecordingsBySymbolId(symbolId: Long)
}
```

### SharedBoardDao

```kotlin
// com.charliechat.data.database.dao.SharedBoardDao
@Dao
interface SharedBoardDao {
    
    @Query("SELECT * FROM shared_boards WHERE share_id = :shareId")
    suspend fun getSharedBoardById(shareId: Long): SharedBoard?
    
    @Query("SELECT * FROM shared_boards WHERE board_id = :boardId")
    suspend fun getSharedBoardsByBoardId(boardId: Long): List<SharedBoard>
    
    @Query("SELECT * FROM shared_boards WHERE shared_with_user_id = :userId")
    suspend fun getSharedBoardsReceived(userId: Long): List<SharedBoard>
    
    @Query("SELECT * FROM shared_boards WHERE shared_by_user_id = :userId")
    suspend fun getSharedBoardsSent(userId: Long): List<SharedBoard>
    
    @Query("SELECT * FROM shared_boards WHERE shared_with_user_id = :userId AND status = 'pending'")
    suspend fun getPendingShares(userId: Long): List<SharedBoard>
    
    @Query("SELECT * FROM shared_boards WHERE shared_with_user_id = :userId AND status = 'accepted'")
    suspend fun getAcceptedShares(userId: Long): List<SharedBoard>
    
    @Query("SELECT * FROM shared_boards WHERE board_id = :boardId AND shared_with_user_id = :userId")
    suspend fun getSharedBoard(boardId: Long, userId: Long): SharedBoard?
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertSharedBoard(sharedBoard: SharedBoard): Long
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertSharedBoards(sharedBoards: List<SharedBoard>): List<Long>
    
    @Update
    suspend fun updateSharedBoard(sharedBoard: SharedBoard)
    
    @Delete
    suspend fun deleteSharedBoard(sharedBoard: SharedBoard)
    
    @Query("DELETE FROM shared_boards WHERE board_id = :boardId")
    suspend fun deleteSharedBoardsByBoardId(boardId: Long)
    
    @Query("UPDATE shared_boards SET status = :status WHERE share_id = :shareId")
    suspend fun updateStatus(shareId: Long, status: String)
    
    @Query("UPDATE shared_boards SET status = 'declined' WHERE share_id = :shareId")
    suspend fun declineShare(shareId: Long)
    
    @Query("UPDATE shared_boards SET status = 'accepted' WHERE share_id = :shareId")
    suspend fun acceptShare(shareId: Long)
}
```

---

## 6. Relationship Classes

### ProfileWithBoards

```kotlin
// com.charliechat.data.database.relation.ProfileWithBoards
data class ProfileWithBoards(
    @Embedded
    val profile: Profile,
    
    @Relation(
        parentColumn = "profile_id",
        entityColumn = "profile_id"
    )
    val boards: List<Board>
)
```

### BoardWithSymbols

```kotlin
// com.charliechat.data.database.relation.BoardWithSymbols
data class BoardWithSymbols(
    @Embedded
    val board: Board,
    
    @Relation(
        parentColumn = "board_id",
        entityColumn = "board_id"
    )
    val symbols: List<Symbol>
)
```

### BoardWithSubBoards

```kotlin
// com.charliechat.data.database.relation.BoardWithSubBoards
data class BoardWithSubBoards(
    @Embedded
    val board: Board,
    
    @Relation(
        parentColumn = "board_id",
        entityColumn = "parent_board_id"
    )
    val subBoards: List<Board>
)
```

### SymbolWithCategory

```kotlin
// com.charliechat.data.database.relation.SymbolWithCategory
data class SymbolWithCategory(
    @Embedded
    val symbol: Symbol,
    
    @Relation(
        parentColumn = "category_id",
        entityColumn = "category_id"
    )
    val category: SymbolCategory?
)
```

### CategoryWithSubCategories

```kotlin
// com.charliechat.data.database.relation.CategoryWithSubCategories
data class CategoryWithSubCategories(
    @Embedded
    val category: SymbolCategory,
    
    @Relation(
        parentColumn = "category_id",
        entityColumn = "parent_category_id"
    )
    val subCategories: List<SymbolCategory>
)
```

---

## 7. Migration Strategy

### Migration from Version 1 to Version 2

```kotlin
// com.charliechat.data.database.migration.Migration1To2
val MIGRATION_1_2 = object : Migration(1, 2) {
    override fun migrate(database: SupportSQLiteDatabase) {
        // Add new columns to boards table
        database.execSQL(
            "ALTER TABLE boards ADD COLUMN adjustable_layout INTEGER DEFAULT 0 NOT NULL"
        )
        database.execSQL(
            "ALTER TABLE boards ADD COLUMN box_scale REAL DEFAULT 1.0 NOT NULL"
        )
        database.execSQL(
            "ALTER TABLE boards ADD COLUMN tile_height REAL DEFAULT 100.0 NOT NULL"
        )
        database.execSQL(
            "ALTER TABLE boards ADD COLUMN tile_width REAL DEFAULT 100.0 NOT NULL"
        )
        
        // Add new columns to symbols table
        database.execSQL(
            "ALTER TABLE symbols ADD COLUMN row INTEGER"
        )
        database.execSQL(
            "ALTER TABLE symbols ADD COLUMN column INTEGER"
        )
        database.execSQL(
            "ALTER TABLE symbols ADD COLUMN is_favorite INTEGER DEFAULT 0 NOT NULL"
        )
        database.execSQL(
            "ALTER TABLE symbols ADD COLUMN usage_count INTEGER DEFAULT 0 NOT NULL"
        )
        database.execSQL(
            "ALTER TABLE symbols ADD COLUMN last_used_at INTEGER"
        )
        
        // Create new indexes
        database.execSQL(
            "CREATE INDEX IF NOT EXISTS index_symbols_is_favorite ON symbols(is_favorite)"
        )
        database.execSQL(
            "CREATE INDEX IF NOT EXISTS index_symbols_usage_count ON symbols(usage_count)"
        )
    }
}
```

### Migration from Version 2 to Version 3

```kotlin
// com.charliechat.data.database.migration.Migration2To3
val MIGRATION_2_3 = object : Migration(2, 3) {
    override fun migrate(database: SupportSQLiteDatabase) {
        // Add cloud_id and synced_at columns to all tables
        database.execSQL(
            "ALTER TABLE boards ADD COLUMN cloud_id TEXT"
        )
        database.execSQL(
            "ALTER TABLE boards ADD COLUMN synced_at INTEGER"
        )
        
        database.execSQL(
            "ALTER TABLE symbols ADD COLUMN cloud_id TEXT"
        )
        database.execSQL(
            "ALTER TABLE symbols ADD COLUMN synced_at INTEGER"
        )
        
        database.execSQL(
            "ALTER TABLE symbol_categories ADD COLUMN cloud_id TEXT"
        )
        
        database.execSQL(
            "ALTER TABLE sentences ADD COLUMN cloud_id TEXT"
        )
        database.execSQL(
            "ALTER TABLE sentences ADD COLUMN synced_at INTEGER"
        )
        
        database.execSQL(
            "ALTER TABLE audio_recordings ADD COLUMN cloud_id TEXT"
        )
        database.execSQL(
            "ALTER TABLE audio_recordings ADD COLUMN synced_at INTEGER"
        )
        
        // Add is_deleted column to boards
        database.execSQL(
            "ALTER TABLE boards ADD COLUMN is_deleted INTEGER DEFAULT 0 NOT NULL"
        )
        
        // Create index for is_deleted
        database.execSQL(
            "CREATE INDEX IF NOT EXISTS index_boards_is_deleted ON boards(is_deleted)"
        )
    }
}
```

### All Migrations Array

```kotlin
// com.charliechat.data.database.Charlie ChatDatabase
companion object {
    val ALL_MIGRATIONS = arrayOf<Migration>(
        MIGRATION_1_2,
        MIGRATION_2_3
        // Add future migrations here
    )
}
```

---

## 8. Database Helper

```kotlin
// com.charliechat.data.database.DatabaseHelper
class DatabaseHelper @Inject constructor(
    private val context: Context
) {
    
    private val database: Charlie ChatDatabase by lazy {
        Charlie ChatDatabase.getDatabase(context)
    }
    
    // DAO accessors
    val userDao: UserDao = database.userDao()
    val profileDao: ProfileDao = database.profileDao()
    val boardDao: BoardDao = database.boardDao()
    val symbolDao: SymbolDao = database.symbolDao()
    val symbolCategoryDao: SymbolCategoryDao = database.symbolCategoryDao()
    val sentenceDao: SentenceDao = database.sentenceDao()
    val favoriteDao: FavoriteDao = database.favoriteDao()
    val settingDao: SettingDao = database.settingDao()
    val languageDao: LanguageDao = database.languageDao()
    val audioRecordingDao: AudioRecordingDao = database.audioRecordingDao()
    val sharedBoardDao: SharedBoardDao = database.sharedBoardDao()
    
    // Transaction helpers
    suspend fun <T> withTransaction(block: suspend () -> T): T {
        return database.withTransaction(block)
    }
    
    // Clear all data (for testing or logout)
    suspend fun clearAllData() {
        withTransaction {
            database.sharedBoardDao().deleteAll()
            database.favoriteDao().deleteAll()
            database.sentenceDao().deleteAll()
            database.symbolDao().deleteAll()
            database.symbolCategoryDao().deleteAll()
            database.boardDao().deleteAll()
            database.profileDao().deleteAll()
            database.audioRecordingDao().deleteAll()
            database.settingDao().deleteAll()
        }
    }
}
```

---

## 9. Repository Pattern

```kotlin
// com.charliechat.data.repository.BoardRepository
class BoardRepository @Inject constructor(
    private val databaseHelper: DatabaseHelper,
    private val boardDao: BoardDao = databaseHelper.boardDao,
    private val symbolDao: SymbolDao = databaseHelper.symbolDao
) {
    
    suspend fun getBoard(boardId: Long): Board? {
        return boardDao.getBoardById(boardId)
    }
    
    suspend fun getBoards(profileId: Long): List<Board> {
        return boardDao.getBoardsByProfileId(profileId)
    }
    
    suspend fun getBoardWithSymbols(boardId: Long): BoardWithSymbols? {
        return boardDao.getBoardWithSymbols(boardId)
    }
    
    suspend fun saveBoard(board: Board): Long {
        return boardDao.insertOrReplace(board)
    }
    
    suspend fun saveBoardWithSymbols(board: Board, symbols: List<Symbol>) {
        databaseHelper.withTransaction {
            val boardId = boardDao.insertOrReplace(board)
            symbols.forEach { symbol ->
                symbolDao.insertOrReplace(symbol.copy(boardId = boardId))
            }
        }
    }
    
    suspend fun deleteBoard(boardId: Long) {
        boardDao.softDeleteBoard(boardId)
    }
    
    suspend fun searchBoards(query: String): List<Board> {
        return boardDao.searchBoards("%$query%")
    }
}
```

---

## 10. Summary

This Room database schema provides:

1. **Complete Entity Definitions** - All 11 tables with proper annotations
2. **Primary Keys** - Auto-generated Long IDs for all entities
3. **Foreign Keys** - Proper relationships with cascade deletes
4. **Indices** - Performance indexes on frequently queried columns
5. **DAO Interfaces** - Complete CRUD operations for all entities
6. **Relationship Classes** - Embedded and relation annotations for complex queries
7. **Migration Strategy** - Version migrations with SQL statements
8. **Type Converters** - Converters for Date, List, Map, and Boolean types
9. **Database Helper** - Singleton access with transaction support
10. **Repository Pattern** - Abstraction layer for data access

---

**Related Documents:**
- [UNIVERSAL_DATABASE.md](UNIVERSAL_DATABASE.md)
- [CLEAN_ARCHITECTURE.md](CLEAN_ARCHITECTURE.md)
- [DATA_LAYER.md](DATA_LAYER.md)

---

**Document Version:** 1.0  
**Last Updated:** June 2026
