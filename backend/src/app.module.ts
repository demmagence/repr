import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ScheduleModule } from '@nestjs/schedule';
import { join } from 'path';
import { existsSync } from 'fs';
import { ServeStaticModule } from '@nestjs/serve-static';
import { AppController } from './app.controller.js';
import { AppService } from './app.service.js';
import { Exercise } from './exercises/entities/exercise.entity.js';
import { ExercisesModule } from './exercises/exercises.module.js';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
    }),
    ServeStaticModule.forRoot({
      rootPath: existsSync(join(process.cwd(), 'public'))
        ? join(process.cwd(), 'public')
        : join(process.cwd(), 'backend', 'public'),
      serveRoot: '/media',
    }),
    ScheduleModule.forRoot(),
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        type: 'postgres',
        host: config.get<string>('DB_HOST', 'localhost'),
        port: config.get<number>('DB_PORT', 5432),
        username: config.get<string>('DB_USERNAME', 'postgres'),
        password: config.get<string>('DB_PASSWORD', 'postgrespassword'),
        database: config.get<string>('DB_NAME', 'exercisedb'),
        entities: [Exercise],
        synchronize: true, // auto create schema in development
      }),
    }),
    ExercisesModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
