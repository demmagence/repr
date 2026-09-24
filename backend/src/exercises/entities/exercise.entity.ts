import { Entity, Column, PrimaryColumn, CreateDateColumn, UpdateDateColumn } from 'typeorm';

@Entity('exercises')
export class Exercise {
  @PrimaryColumn({ type: 'varchar', length: 64 })
  id: string;

  @Column({ type: 'varchar', length: 255 })
  name: string;

  @Column({ type: 'varchar', length: 128 })
  bodyPart: string;

  @Column({ type: 'varchar', length: 128 })
  equipment: string;

  @Column({ type: 'text', nullable: true })
  gifUrl: string;

  @Column({ type: 'varchar', length: 128 })
  target: string;

  @Column('simple-array', { nullable: true })
  secondaryMuscles: string[];

  @Column('simple-array', { nullable: true })
  instructions: string[];

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
